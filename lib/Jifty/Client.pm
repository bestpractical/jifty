use strict;
use warnings;

package Jifty::Client;
use base qw/WWW::Mechanize/;

delete $ENV{'http_proxy'}; # Otherwise WWW::Mechanize tries to go through your HTTP proxy

use Jifty::YAML;
use HTTP::Cookies;
use XML::XPath;
use List::Util qw(first);
use Carp;

=head1 NAME

Jifty::Client - Subclass of L<WWW::Mechanize> with extra Jifty features

=head1 DESCRIPTION

This module is a base for building robots to interact with Jifty applications.
It currently contains much overlapping code with C<Jifty::Test::WWW::Mechanize>,
except that it does not inherit from C<Test::WWW::Mechanize>.

Expect this code to be refactored in the near future.

=head1 METHODS

=head2 new

Overrides L<WWW::Mechanize>'s C<new> to automatically give the
bot a cookie jar.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->cookie_jar(HTTP::Cookies->new);
    return $self;
} 

=head2 moniker_for ACTION, FIELD1 => VALUE1, FIELD2 => VALUE2

Finds the moniker of the first action of type I<ACTION> whose
"constructor" field I<FIELD1> is I<VALUE1>, and so on.

=cut

sub moniker_for {
  my $self = shift;
  my $action = Jifty->api->qualify(shift);
  my %args = @_;

  # Search through all the inputs of all the forms
  for my $f ($self->forms) {
  INPUT: 
    for my $input ($f->inputs) {

      # Look for the matching action
      if ($input->type eq "hidden" and $input->name =~ /^J:A-(?:\d+-)?(.*)/ and $input->value eq $action) {

        # We have a potential moniker
        my $moniker = $1;

        # Make sure that this action actually has the field values we're
        # looking for, if not keep looking
        for my $id (keys %args) {
          my $idfield = $f->find_input("J:A:F:F-$id-$moniker");
          next INPUT unless $idfield and $idfield->value eq $args{$id};
        }

        # It does! Return it...
        return $1;
      }
    }
  }
  return undef;
}

=head2 fill_in_action MONIKER, FIELD1 => VALUE1, FIELD2 => VALUE2, ...

Finds the fields on the current page with the names FIELD1, FIELD2,
etc in the MONIKER action, and fills them in.  Returns the
L<HTML::Form> object of the form that the action is in, or undef if it
can't find all the fields.

=cut

sub fill_in_action {
    my $self = shift;
    my $moniker = shift;
    my %args = @_;

    # Load the form object containing the given moniker or quit
    my $action_form = $self->action_form($moniker, keys %args);
    return unless $action_form;

    # For each field name given, set the field's value
    for my $arg (keys %args) {
        my $input = $action_form->find_input("J:A:F-$arg-$moniker");
        return unless $input;
        $input->value($args{$arg});
    } 

    # Return the form in case they want to do something with it
    return $action_form;
}

=head2 action_form MONIKER [ARGUMENTNAMES]

Returns the form (as an L<HTML::Form> object) corresponding to the
given moniker (which also contains inputs for the given
argumentnames), and also selects it as the current form.  Returns
undef if it can't be found.

=cut

sub action_form {
    my $self = shift;
    my $moniker = shift;
    my @fields = @_;
    Carp::confess("No moniker") unless $moniker;

    # Go through all the forms looking for the moniker
    my $i;
    for my $form ($self->forms) {
        no warnings 'uninitialized';

        # Keep looking unless the right kind of input is found
        $i++;
        next unless first {   $_->name =~ /J:A-(?:\d+-)?$moniker/
                           && $_->type eq "hidden" }
                        $form->inputs;

        # Keep looking if the suggested field's don't match up
        next if grep {not $form->find_input("J:A:F-$_-$moniker")} @fields;

        $self->form_number($i); #select it, for $mech->submit etc
        return $form;
    } 
    return;
} 

=head2 action_field_value MONIKER, FIELD

Finds the fields on the current page with the names FIELD in the
action MONIKER, and returns its value, or undef if it can't be found.

=cut

sub action_field_value {
    my $self = shift;
    my $moniker = shift;
    my $field = shift;

    # Find the form containing the moniker requested
    my $action_form = $self->action_form($moniker, $field);
    return unless $action_form;
    
    # Find the input containing the field requested and fetch the value
    my $input = $action_form->find_input("J:A:F-$field-$moniker");
    return unless $input;
    return $input->value;
}

=head2 send_action CLASS ARGUMENT => VALUE, [ ... ]

Sends a request to the server via the webservices API, and returns the
L<Jifty::Result> of the action.  C<CLASS> specifies the class of the
action, and all parameters thereafter supply argument keys and values.

The URI of the page is unchanged after this; this is accomplished by
using the "back button" after making the webservice request.

=cut

sub send_action {
    my $self = shift;
    my $class = shift;
    my %args = @_;

    # Setup the URL of the request we're about to make
    my $uri = $self->uri->clone;
    $uri->path("__jifty/webservices/yaml");

    # Setup the action request we're going to send
    my $request = HTTP::Request->new(
        POST => $uri,
        [ 'Content-Type' => 'text/x-yaml' ],
        Jifty::YAML::Dump(
            {   path => $uri->path,
                actions => {
                    action => {
                        moniker => 'action',
                        class   => $class,
                        fields  => \%args
                    }
                }
            }
        )
    );

    # Fire off the request, evaluate the result, and return it
    my $result = $self->request( $request );
    my $content = eval { Jifty::YAML::Load($result->content)->{action} } || undef;
    $self->back;
    return $content;
}

=head2 fragment_request PATH ARGUMENT => VALUE, [ ... ]

Makes a request for the fragment at PATH, using the webservices API,
and returns the string of the result.

=cut

sub fragment_request {
    my $self = shift;
    my $path = shift;
    my %args = @_;

    # Setup the URL we're going to use
    my $uri = $self->uri->clone;
    $uri->path("__jifty/webservices/xml");

    # Setup the request we're going to use
    my $request = HTTP::Request->new(
        POST => $uri,
        [ 'Content-Type' => 'text/x-yaml' ],
        Jifty::YAML::Dump(
            {   path => $uri->path,
                fragments => {
                    fragment => {
                        name  => 'fragment',
                        path  => $path,
                        args  => \%args
                    }
                }
            }
        )
    );

    # Fire the request, evaluate the result, and return it
    my $result = $self->request( $request );
    use XML::Simple;
    my $content = eval { XML::Simple::XMLin($result->content, SuppressEmpty => '')->{fragment}{content} } || '';
    $self->back;
    return $content;
}

=head2 field_error_text MONIKER, FIELD

Finds the error span on the current page for the name FIELD in the
action MONIKER, and returns the text (tags stripped) from it.  (If the
field can't be found, return undef).

=cut

sub field_error_text {
    my $self = shift;
    my $moniker = shift;
    my $field = shift;

    # Setup the XPath processor and the ID we're looking for
    my $xp = XML::XPath->new( xml => $self->content );
    my $id = "errors-J:A:F-$field-$moniker";

    # Search for the span containing that error
    my $nodeset = $xp->findnodes(qq{//span[\@id = "$id"]});
    return unless $nodeset->size == 1;
    
    # Note that $xp->getNodeText does not actually return undef for nodes that
    # aren't found, even though it's documented to.  Thus the workaround above.
    return $xp->getNodeText(qq{//span[\@id = "$id" ]});
} 

=head2 uri

L<WWW::Mechanize> has a bug where it returns the wrong value for
C<uri> after redirect.  This fixes that.  See
http://rt.cpan.org/NoAuth/Bug.html?id=9059

=cut

sub uri { shift->response->request->uri }

=head2 session

Returns the server-side L<Jifty::Web::Session> object associated with
this Mechanize object.

=cut

sub session {
    my $self = shift;

    # We don't have a session!
    return undef unless $self->cookie_jar->as_string =~ /JIFTY_SID_\d+=([^;]+)/;

    # Load the data stored in the session cookie
    my $session = Jifty::Web::Session->new;
    $session->load($1);
    return $session;
}

=head2 continuation [ID]

Returns the current continuation of the Mechanize object, if any.  Or,
given an ID, returns the continuation with that ID.

=cut

sub continuation {
    my $self = shift;

    # If we don't have a session, we don't have a continuation
    my $session = $self->session;
    return undef unless $session;
    
    # Look for the continuation info in the URL
    my $id = shift;
    ($id) = $self->uri =~ /J:(?:C|CALL|RETURN)=([^&;]+)/ unless $id;

    # Return information about the continuation
    return $session->get_continuation($id);
}

=head2 current_user

Returns the L<Jifty::CurrentUser> object or descendant, if any.

=cut

sub current_user {
    my $self = shift;

    # We don't have a current user if we don't have a session
    my $session = $self->session;
    return undef unless $session;

    # Fetch information about user from the session
    my $id = $session->get('user_id');
    my $object = Jifty->app_class("CurrentUser")->new();
    my $user = $session->get('user_ref')->new( current_user => $object );
    $user->load_by_cols( id => $id );
    $object->user_object($user);

    return $object;
}

=head1 SEE ALSO

L<Jifty::Test::WWW::Mechanize>

=head1 LICENSE

Jifty is Copyright 2005-2010 Best Practical Solutions, LLC.
Jifty is distributed under the same terms as Perl itself.

=cut

1;
