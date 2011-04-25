use strict;
use warnings;

package Jifty::Test::WWW::Mechanize;
use base qw/Test::WWW::Mechanize/;

delete $ENV{'http_proxy'}; # Otherwise Test::WWW::Mechanize tries to go through your HTTP proxy

use Test::More;
use Jifty::YAML;
use HTML::Lint;
use Test::HTML::Lint qw();
use HTTP::Cookies;
use HTML::TreeBuilder::XPath;
use List::Util qw/first/;
use Plack::Test;
use Carp;

# XXX TODO: We're leaving out FLUFF errors because it complains about non-standard
# attributes such as "autocomplete" on <form> elements.  There should be a better
# way to fix this.
my $lint = HTML::Lint->new( only_types => [HTML::Lint::Error::STRUCTURE,
                                           HTML::Lint::Error::HELPER] );

=head1 NAME

Jifty::Test::WWW::Mechanize - Subclass of L<Test::WWW::Mechanize> with
extra Jifty features

=head1 METHODS

=head2 new

Overrides L<Test::WWW::Mechanize>'s C<new> to automatically give the
bot a cookie jar.

=cut

my $plack_server_pid;

sub new {
    my ($class, @args) = @_;

    push @args, app => Jifty->handler->psgi_app
        if $class->isa('Test::WWW::Mechanize::PSGI');

    my $self = $class->SUPER::new(@args);
    $self->cookie_jar(HTTP::Cookies->new);

    return $self;
}

=head2 request

We override L<WWW::Mechanize>'s default request method so accept-encoding is
not set to gzip by default.

=cut

sub _modify_request {
    my ($self, $req) = @_;
    $req->header( 'Accept-Encoding', 'identity' )
        unless $req->header( 'Accept-Encoding' );
    return $self->SUPER::_modify_request($req);
}

=head2 moniker_for ACTION, FIELD1 => VALUE1, FIELD2 => VALUE2

Finds the moniker of the first action of type I<ACTION> whose
"constructor" field I<FIELD1> is I<VALUE1>, and so on.

   my $mon = $mech->moniker_for('MyApp::Action::UpdateInfo');

If there is only one action of type ACTION, be sure not to pass
any more arguments to this method, or the method will return undef.

NOTE that if you're using this in a series of different pages or forms, 
you'll need to run it again for each new form:

    $mech->fill_in_action_ok($mech->moniker_for('MyApp::Action::UpdateInfo'),
                             owner_id => 'someone');
    $mech->submit_html_ok();

    is($mech->action_field_value($mech->moniker_for("MyApp::Action::UpdateInfo"),
                                 'owner_id'),
       'someone',
       "Owner was reassigned properly to owner 'someone'");

=cut

sub moniker_for {
  my $self = shift;
  my $action = Jifty->api->qualify(shift);
  my %args = @_;

  for my $f ($self->forms) {
  INPUT: 
    for my $input ($f->inputs) {
      if ($input->type eq "hidden" and $input->name =~ /^J:A-(?:\d+-)?(.*)/ and $input->value eq $action) {

        my $moniker = $1;

        for my $id (keys %args) {
          my $idfield = $f->find_input("J:A:F:F-$id-$moniker")
                     || $f->find_input("J:A:F-$id-$moniker");
          next INPUT unless $idfield and $idfield->value eq $args{$id};
        }

        return $1;
      }
    }
    # if we've gotten to this point, there were no hidden fields with a moniker,
    # possibly a form with only its continuation-marking hidden field.
    # Fall back to a submit field with similar attributes.
    for my $input ($f->inputs) {
        my $name = $input->name || '';

        next unless $input->type eq "submit";
        next unless $name =~ /\Q$action\E/;
        my ($moniker) = $name =~ /J:ACTIONS=([^|]+)\|/
            or next;
        return $moniker;
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

    my $action_form = $self->action_form($moniker, keys %args);
    return unless $action_form;

    for my $arg (keys %args) {
        my $input = $action_form->find_input("J:A:F-$arg-$moniker");
        unless ($input) {
            return;
        } 

        # not $input->value($args{$arg}), because it doesn't handle arrayref
        $action_form->param( $input->name, $args{$arg} );
    } 

    return $action_form;
}

=head2 fill_in_action_ok MONIKER, FIELD1 => VALUE1, FIELD2 => VALUE2, ...

Finds the fields on the current page with the names FIELD1, FIELD2,
etc in the MONIKER action, and fills them in.  Returns the
L<HTML::Form> object of the form that the action is in, or undef if it
can't find all the fields.

Also, passes if it finds all of the fields and fails if any of the
fields are missing.

=cut

sub fill_in_action_ok {
    my $self = shift;
    my $moniker = shift;

    my $ret = $self->fill_in_action($moniker, @_);
    my $Test = Test::Builder->new;
    $Test->ok($ret, "Filled in action $moniker");
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

    my $i;
    for my $form ($self->forms) {
        no warnings 'uninitialized';

        $i++;
        next unless first {   $_->name =~ /J:A-(?:\d+-)?$moniker/
                           && $_->type eq "hidden" }
                        $form->inputs;
        next if grep {not $form->find_input("J:A:F-$_-$moniker")} @fields;

        $self->form_number($i); #select it, for $mech->submit etc
        return $form;
    } 

    # A fallback for forms that don't have any named fields except their
    # submit button. Could stand to be refactored.
    $i = 0;
    for my $form ($self->forms) {
        no warnings 'uninitialized';

        $i++;
        next unless first {   $_->name =~ /J:A-(?:\d+-)?$moniker/
                           && $_->type eq "submit" }
                        $form->inputs;
        next if grep {not $form->find_input("J:A:F-$_-$moniker")} @fields;

        $self->form_number($i); #select it, for $mech->submit etc
        return $form;
    } 
    return;
} 

=head2 action_field_input MONIKER, FIELD

Finds the field on the current page with the names FIELD in the
action MONIKER, and returns its L<HTML::Form::Input>, or undef if it can't be
found.

=cut

sub action_field_input {
    my $self = shift;
    my $moniker = shift;
    my $field = shift;

    my $action_form = $self->action_form($moniker, $field);
    return unless $action_form;

    my $input = $action_form->find_input("J:A:F-$field-$moniker");
    return $input;
}

=head2 action_field_value MONIKER, FIELD

Finds the field on the current page with the names FIELD in the
action MONIKER, and returns its value, or undef if it can't be found.

=cut

sub action_field_value {
    my $self = shift;
    my $input = $self->action_field_input(@_);
    return $input ? $input->value : undef;
}

=head2 send_action CLASS ARGUMENT => VALUE, [ ... ]

Sends a request to the server via the webservices API, and returns the
L<Jifty::Result> of the action.  C<CLASS> specifies the class of the
action, and all parameters thereafter supply argument keys and values.

The URI of the page is unchanged after this; this is accomplished by
using the "back button" after making the webservice request.

=cut

sub _build_webservices_request {
    my ($self, $endpoint, $data) = @_;

    my $uri = $self->uri->clone;
    $uri->path($endpoint);
    $uri->query('');

    my $body = Jifty::YAML::Dump({ path => $endpoint, %$data});

    HTTP::Request->new(
        POST => $uri,
        [ 'Content-Type' => 'text/x-yaml',
          'Content-Length' => length($body) ],
        $body
    );
}

sub send_action {
    my $self = shift;
    my $class = shift;
    my %args = @_;

    my $request = $self->_build_webservices_request
        ( "__jifty/webservices/yaml",
          { actions => {
                action => {
                    moniker => 'action',
                    class   => $class,
                    fields  => \%args
                }
            }
        });

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

    my $request = $self->_build_webservices_request
        ( "__jifty/webservices/xml",
          { fragments => {
                fragment => {
                    name  => 'fragment',
                    path  => $path,
                    args  => \%args
                }
            }
        });

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
    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->parse($self->content);
    $tree->eof;

    my $id = "errors-J:A:F-$field-$moniker";

    # Search for the span containing that error
    return $tree->findvalue(qq{//span[\@id = "$id"]});
}

=head2 uri

L<WWW::Mechanize> has a bug where it returns the wrong value for
C<uri> after redirect.  This fixes that.  See
http://rt.cpan.org/NoAuth/Bug.html?id=9059

=cut

sub uri { shift->response->request->uri }

=head2 get_html_ok URL

Calls C<get> URL, followed by testing the HTML using
L<Test::HTML::Lint>.

=cut

sub get_html_ok {
    my $self = shift;
    $self->get(@_);
    {
        local $Test::Builder::Level = $Test::Builder::Level;
        $Test::Builder::Level++;
        Test::HTML::Lint::html_ok( $lint, $self->content, "html_ok for ".$self->uri );
    }
}

=head2 html_ok [STRING]

Tests the current C<content> using L<Test::HTML::Lint>.  If passed a string,
tests against that instead of the current content.

=cut 

sub html_ok {
    my $self    = shift;
    my $content = shift || $self->content;
    {
        local $Test::Builder::Level = $Test::Builder::Level;
        $Test::Builder::Level++;
        Test::HTML::Lint::html_ok( $lint, $content );
    }
}

=head2 submit_html_ok 

Calls C<submit>, followed by testing the HTML using
L<Test::HTML::Lint>.

=cut

sub submit_html_ok {
    my $self = shift;
    $self->submit(@_);
    {
        local $Test::Builder::Level = $Test::Builder::Level;
        $Test::Builder::Level++;
        Test::HTML::Lint::html_ok( $lint, $self->content );
    }
} 

=head2 follow_link_ok 

Calls C<follow_link>, followed by testing the HTML using
L<Test::HTML::Lint>.  Warns if it cannot find the specified link (you
should use C<ok> on C<find_link> first to check its existence).

=cut

sub follow_link_ok {
    my $self = shift;


    my $desc;

    # Test::WWW::Mechanize allows passing in a hashref of arguments, so we should to
    if  ( ref($_[0]) eq 'HASH') {
        # if the user is pashing in { text => 'foo' } ...
        $desc = $_[1] if $_[1];
        @_ = %{$_[0]};
    } elsif (@_ % 2 ) {
        # IF the user is passing in text => 'foo' ,"Cicked the right thing"
        # Remove reason from end if it's there
        $desc = pop @_ ;
    }

    carp("Couldn't find link") unless $self->follow_link(@_);
    {
        local $Test::Builder::Level = $Test::Builder::Level;
        $Test::Builder::Level++;
        Test::HTML::Lint::html_ok( $lint, $self->content, $desc );
    }
}

=head2 warnings_like WARNING, [REASON]

Tests that the warnings generated by the server (since the last such
check) match the given C<WARNING>, which should be a regular
expression.  If an array reference of regular expressions is passed as
C<WARNING>, checks that one warning per element was received.

=cut

sub warnings_like {
    my $self = shift;
    my @args = shift;
    @args = @{$args[0]} if ref $args[0] eq "ARRAY";
    my $reason = pop || "Server warnings matched";

    local $Test::Builder::Level = $Test::Builder::Level;
    $Test::Builder::Level++;

    my $plugin = Jifty->find_plugin("Jifty::Plugin::TestServerWarnings");
    my @warnings = $plugin->decoded_warnings($self->uri);
    my $max = @warnings > @args ? $#warnings : $#args;
    for (0 .. $max) {
        like($warnings[$_], $_ <= $#args ? qr/$args[$_]/ : qr/(?!unexpected)unexpected warning/, $reason);
    }
}

=head2 no_warnings_ok [REASON]

Checks that no warnings were generated by the server (since the last
such check).

=cut

sub no_warnings_ok {
    my $self = shift;
    my $reason = shift || "no warnings emitted";

    local $Test::Builder::Level = $Test::Builder::Level;
    $Test::Builder::Level++;

    my $plugin   = Jifty->find_plugin("Jifty::Plugin::TestServerWarnings");
    my @warnings = $plugin->decoded_warnings( $self->uri );

    is( @warnings, 0, $reason );
    for (@warnings) {
        diag("got warning: $_");
    }
}

=head2 session

Returns the server-side L<Jifty::Web::Session> object associated with
this Mechanize object.

=cut

sub session {
    my $self = shift;

    my $cookie = Jifty->config->framework('Web')->{'SessionCookieName'};
    $cookie =~ s/\$PORT/(?:\\d+|NOPORT)/g;

    return undef unless $self->cookie_jar->as_string =~ /$cookie=([^;]+)/;

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

    my $session = $self->session;
    return undef unless $session;
    
    my $id = shift;
    ($id) = $self->uri =~ /J:(?:C|CALL|RETURN)=([^&;]+)/ unless $id;

    return $session->get_continuation($id);
}

=head2 current_user

Returns the L<Jifty::CurrentUser> object or descendant, if any.

=cut

sub current_user {
    my $self = shift;

    my $session = $self->session;
    return undef unless $session;

    my $id = $session->get('user_id');

    return undef unless ($id);

    my $object = Jifty->app_class("CurrentUser")->new(id => $id);
    return $object;
}


1;
