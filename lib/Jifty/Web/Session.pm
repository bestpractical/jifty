use warnings;
use strict;

package Jifty::Web::Session;
use base qw/Jifty::Object/;
use CGI::Cookie;
use DateTime;

=head1 NAME

Jifty::Web::Session - A Jifty session handler

=cut

=head1 new

Returns a new, empty session.

=cut

sub new {
    my $class = shift;
    return bless {}, $class;
}

=head2 id

Returns the session's id if it has been loaded, or C<undef> otherwise.

=cut

sub id {
    my $self = shift;
    return $self->loaded ? $self->_session->session_id : undef;
}

=head2 load [ID]

Load up the current session from the given C<ID>, or the appropriate
cookie (see L</cookie_name>) otherwise.  If both of those fail,
creates a session in the database.

=cut

sub load {
    my $self       = shift;
    my $session_id = shift;

    unless ($session_id) {
        my %cookies    = CGI::Cookie->fetch();
        my $cookiename = $self->cookie_name;
        $session_id
            = $cookies{$cookiename} ? $cookies{$cookiename}->value() : undef;
    }

    my $session = Jifty::Model::Session->new;
    $session->load_by_cols(
        session_id => $session_id,
        key_type   => "session"
        )
        if $session_id;

    $session->create( key_type => "session" ) unless $session->id;
    $self->_session($session);
}

=head2 unload

Flush the session, and leaves the session object blank.

=cut

sub unload {
    my $self = shift;

    return unless $self->loaded;
    $self->_session(undef);
}

=head2 loaded

Returns true if the session has already been loaded.

=cut

sub loaded {
    my $self = shift;
    return $self->_session;
}

sub _session {
    my $self = shift;
    $self->{'_session'} = shift if (@_);
    return ( $self->{'_session'} );
}

=head2 get KEY [TYPE]

Returns the value for C<KEY> for the current user's session.  C<TYPE>,
which defaults to "key", allows accessing of other namespaces in the
session, including "metadata" and "continuation".

=cut

sub get {
    my $self     = shift;
    my $key      = shift;
    my $key_type = shift || "key";

    return undef unless $self->loaded;

    my $setting = Jifty::Model::Session->new;
    $setting->load_by_cols(
        session_id => $self->id,
        key_type   => $key_type,
        key        => $key
    );
    return $setting->value;
}

=head2 set KEY => VALUE, [TYPE]

Sets the value C<VALUE> for C<KEY> for the session.  C<TYPE>, which
defaults to "key", allows values to be set in other namespaces,
including "metadata" and "continuation".

=cut

sub set {
    my $self     = shift;
    my $key      = shift;
    my $value    = shift;
    my $key_type = shift || "key";

    return undef unless $self->loaded;
    $self->_session->set_updated( DateTime->now );

    my $setting = Jifty::Model::Session->new;
    $setting->load_by_cols(
        session_id => $self->id,
        key_type   => $key_type,
        key        => $key
    );
    if ( $setting->id ) {
        $setting->set_value($value);
    } else {
        $setting->create(
            session_id => $self->id,
            key_type   => $key_type,
            key        => $key,
            value      => $value
        );
    }
}

=head2 remove KEY, [TYPE]

Remove key C<KEY> from the cache.  C<TYPE> defaults to "key".

=cut

sub remove {
    my $self     = shift;
    my $key      = shift;
    my $key_type = shift || "key";

    return undef unless $self->loaded;
    $self->_session->set_updated( DateTime->now );

    my $setting = Jifty::Model::Session->new;
    $setting->load_by_cols(
        session_id => $self->id,
        key_type   => $key_type,
        key        => $key
    );
    $setting->delete if $setting->id;
}

=head2 set_continuation ID CONT

Stores a continuation in the session.

=cut

sub set_continuation {
    my $self = shift;
    $self->set( @_, "continuation" );
}

=head2 get_continuation ID

Pulls a continuation from the current session. Expects a continuation
C<ID>.

=cut

sub get_continuation {
    my $self = shift;
    $self->get( @_, "continuation" );

}

=head2 remove_continuation ID

Removes a continuation with id C<ID> from the store.

=cut

sub remove_continuation {
    my $self = shift;
    $self->remove( @_, "continuation" );
}

=head2 continuations

Return a hash of all the continuations in this session, keyed by the
continuations' C<id>.

=cut

sub continuations {
    my $self = shift;

    return () unless $self->loaded;

    my $conts = Jifty::Model::SessionCollection->new;
    $conts->limit( column => "key_type",   value => "continuation" );
    $conts->limit( column => "session_id", value => $self->id );

    my %continuations;
    $continuations{ $_->key } = $_->value while $_ = $conts->next;
    return %continuations;
}

=head2 set_cookie

Sets the session cookie.

=cut

sub set_cookie {
    my $self = shift;

    my $cookie_name = $self->cookie_name;
    my %cookies     = CGI::Cookie->fetch();
    my $session_id
        = $cookies{$cookie_name} ? $cookies{$cookie_name}->value() : undef;
    my $cookie = new CGI::Cookie(
        -name    => $cookie_name,
        -value   => $self->id,
        -expires => $self->expires,
    );

    # XXX TODO might need to change under mod_perl
    if ( not $cookies{$cookie_name}
        or ( $cookies{$cookie_name} ne $cookie->as_string ) )
    {
        Jifty->web->response->add_header(
            'Set-Cookie' => $cookie->as_string );
    }
}

=head2 cookie_name

Returns the current session's cookie_name -- it is the same for all
users, but various accorting to the port the server is running on.

=cut

sub cookie_name {
    my $self = shift;
    my $cookiename = "JIFTY_SID_" . ( $ENV{'SERVER_PORT'} || 'NOPORT' );
    return ($cookiename);
}

=head2 expires [VALUE]

Get or set the session's expiration date, in a format expected by
Cache::Cache.

=cut

sub expires {
    my $self = shift;
    $self->set( 'expires' => shift, "metadata" ) if @_;
    return ( $self->get( 'expires', "metadata" ) );
}

1;
