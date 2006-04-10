use strict;
use warnings;

package Jifty::Test::WWW::Mechanize;
use base qw/Test::WWW::Mechanize/;

use Test::HTML::Lint; # exports html_ok
use HTTP::Cookies;
use XML::XPath;
use Hook::LexWrap;

my $Test = Test::Builder->new;

=head1 NAME

Jifty::Test::WWW::Mechanize - Subclass of L<Test::WWW::Mechanize> with extra Jifty features

=head1 METHODS

=head2 new

Overrides L<Test::WWW::Mechanize>'s C<new> to automatically give the bot a cookie jar.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->cookie_jar(HTTP::Cookies->new);
    return $self;
} 

=head2 moniker_for ACTION, FIELD1 => VALUE1, FIELD2 => VALUE2

Finds the moniker of the first action of type I<ACTION> whose "constructor"
field I<FIELD1> is I<VALUE1>, and so on.

=cut

sub moniker_for {
  my $self = shift;
  my $action = Jifty->api->qualify(shift);
  my %args = @_;

  for my $f ($self->forms) {
  INPUT: 
    for my $input ($f->inputs) {
      if ($input->type eq "hidden" and $input->name =~ /^J:A-(.*)/ and $input->value eq $action) {

        my $moniker = $1;

        for my $id (keys %args) {
          my $idfield = $f->find_input("J:A:F:F:F-$id-$moniker");
          next INPUT unless $idfield and $idfield->value eq $args{$id};
        }

        return $1;
      }
    }
  }
  return undef;
}

=head2 fill_in_action MONIKER, FIELD1 => VALUE1, FIELD2 => VALUE2, ...

Finds the fields on the current page with the names FIELD1, FIELD2, etc in the MONIKER
action, and fills them in.  Returns the L<HTML::Form> object of the form
that the action is in, or undef if it can't find all the fields.

=cut

sub fill_in_action {
    my $self = shift;
    my $moniker = shift;
    my %args = @_;

    my $action_form = $self->action_form($moniker);
    
    unless ($action_form) {
        return;
    } 

    for my $arg (keys %args) {
        my $input = $action_form->find_input("J:A:F-$arg-$moniker");
        unless ($input) {
            return;
        } 
        $input->value($args{$arg});
    } 

    return $action_form;
}

=head2 fill_in_action_ok MONIKER, FIELD1 => VALUE1, FIELD2 => VALUE2, ...

Finds the fields on the current page with the names FIELD1, FIELD2, etc in the MONIKER
action, and fills them in.  Returns the L<HTML::Form> object of the form
that the action is in, or undef if it can't find all the fields.

Also, passes if it finds all of the fields and fails if any of the fields are missing.

=cut

sub fill_in_action_ok {
    my $self = shift;
    my $moniker = shift;

    my $ret = $self->fill_in_action($moniker, @_);
    $Test->ok($ret, "Filled in action $moniker");
} 

=head2 action_form MONIKER

Returns the form (as an L<HTML::Form> object) corresponding to the given moniker, and
also selects it as the current form.  Returns undef if it can't be found.

=cut

sub action_form {
    my $self = shift;
    my $moniker = shift;
    Carp::confess("No moniker") unless $moniker;

    my $i;
    for my $form ($self->forms) {
        $i++;
        if ($form->find_input("J:A-$moniker", "hidden")) {
            $self->form_number($i); #select it, for $mech->submit etc
            return $form;
        } 
    } 
    return;
} 

=head2 action_field_value MONIKER, FIELD

Finds the fields on the current page with the names FIELD in the action 
MONIKER, and returns its value, or undef if it can't be found.

=cut

sub action_field_value {
    my $self = shift;
    my $moniker = shift;
    my $field = shift;

    my $action_form = $self->action_form($moniker);
    return unless $action_form;
    
    my $input = $action_form->find_input("J:A:F-$field-$moniker");
    return unless $input;
    return $input->value;
}

=head2 field_error_text MONIKER, FIELD

Finds the error span on the current page for the name FIELD in the action
MONIKER, and returns the text (tags stripped) from it.  (If the field can't be
found.

=cut

# When it sees something like
# http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd as a DOCTYPE, this will make
# it open dtd/xhtml1-strict.dtd instead -- great for offline hacking!
 
# This "require" is just to give us something to hook on to, and to prevent a
# future require from taking effect.
require 'XML/Parser/LWPExternEnt.pl';
wrap 'XML::Parser::lwp_ext_ent_handler', pre => sub {
    $_[2] =~ s{ \A .+ / ([^/]+) \z }{dtd/$1}xms;
    open my $fh, '<', $_[2] or die "can't open $_[2]: $!";
    my $content = do {local $/; <$fh>};
    close $fh;
    $_[-1] = $content; # override return value
};
wrap 'XML::Parser::lwp_ext_ent_cleanup', pre => sub {
    $_[-1] = 1; # just return please
};

sub field_error_text {
    my $self = shift;
    my $moniker = shift;
    my $field = shift;

    my $xp = XML::XPath->new( xml => $self->content );

    my $id = "errors-J:A:F-$field-$moniker";

    my $nodeset = $xp->findnodes(qq{//span[\@id = "$id"]});
    return unless $nodeset->size == 1;
    
    # Note that $xp->getNodeText does not actually return undef for nodes that
    # aren't found, even though it's documented to.  Thus the workaround above.
    return $xp->getNodeText(qq{//span[\@id = "$id" ]});
} 

=head2 uri

L<WWW::Mechanize> has a bug where it returns the wrong value for C<uri> after
redirect.  This fixes that.  See http://rt.cpan.org/NoAuth/Bug.html?id=9059

=cut

sub uri { shift->response->request->uri }

=head2 get_html_ok URL

Calls C<get> URL, followed by testing the HTML using L<Test::HTML::Lint>.

=cut

sub get_html_ok {
    my $self = shift;
    $self->get(@_);
    # TODO XXX FIXME play with $Test::Builder::Level to get errors reported from
    # right place?
    html_ok($self->content);
} 

=head2 submit_html_ok 

Calls C<submit>, followed by testing the HTML using L<Test::HTML::Lint>.

=cut

sub submit_html_ok {
    my $self = shift;
    $self->submit(@_);
    # TODO XXX FIXME play with $Test::Builder::Level to get errors reported from
    # right place?
    html_ok($self->content);
} 

=head2 follow_link_ok 

Calls C<follow_link>, followed by testing the HTML using
L<Test::HTML::Lint>.  Warns if it cannot find the specified link (you
should use C<ok> on C<find_link> first to check its existence).

=cut

sub follow_link_ok {
    my $self = shift;

    # Remove reason from end if it's there
    pop @_ if @_ % 2;

    warn("Couldn't find link") unless
      $self->follow_link(@_);
    # TODO XXX FIXME play with $Test::Builder::Level to get errors reported from
    # right place?
    html_ok($self->content);
} 

=head2 session

Returns the server-side L<Jifty::Web::Session> object associated with
this Mechanize object.

=cut

sub session {
    my $self = shift;

    return undef unless $self->cookie_jar->as_string =~ /JIFTY_SID_\d+=([^;]+)/;

    my $session = Jifty::Web::Session->new;
    $session->load($1);
    $session->_session->release_all_locks();
    return $session;
}

=head2 continuation [ID]

Returns the current continuation of the Mechanize object, if any.  Or,
given an ID, returns the continuation with that ID.

=cut

sub continuation {
    my $self = shift;

    my $session = $self->session;
    return undef unless $session;
    
    my $id = shift;
    ($id) = $self->uri =~ /J:C(?:ALL)?=([^&;]+)/ unless $id;

    return $session->get_continuation($id);
}

=head2 current_user

Returns the L<Jifty::CurrentUser> object or descendant, if any.

=cut

sub current_user {
    my $self = shift;

    my $session = $self->session;
    return undef unless $session;

    return $session->get('user');
}

1;
