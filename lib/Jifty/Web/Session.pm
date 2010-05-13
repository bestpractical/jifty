use warnings;
use strict;

package Jifty::Web::Session;
use base qw/Jifty::Object/;
use DateTime    ();

=head1 NAME

Jifty::Web::Session - A Jifty session handler

=head1 SYNOPSIS

In your F<etc/config.yml> (optional):

  framework:
    Web:
      # The default ($PORT is replaced by the port the app is running on)
      SessionCookieName: JIFTY_SID_$PORT

=head2 new

Returns a new, empty session.

=cut

sub new {
    my $class = shift;

    my $session_class = Jifty->config->framework('Web')->{'SessionClass'} || 'Jifty::Web::Session::JDBI';
    my $cookie_name = Jifty->config->framework('Web')->{'SessionCookieName'};
        Jifty::Util->require($session_class);
        return $session_class->new(@_);
}

=head2 id

Returns the session's id if it has been loaded, or C<undef> otherwise.

=cut

sub id {
    die "Subclass must implement 'id'";
}

=head2 load [ID]

Load up the current session from the given C<ID>, or the appropriate
cookie (see L</cookie_name>) otherwise.  If both of those fail,
creates a session in the database.

=cut

sub load {
    die "Subclass must implement 'load'";
}

=head2 load_by_kv key => value 

Load up the current session from the given (key, value) pair. If no matching
session could be found, it will create a new session with the key, value set.
Be sure that what you're loading by is unique. If you're loading a session
based on, say, a timestamp, then you're asking for trouble.

=cut

sub load_by_kv {
    die "Subclass must implement load_by_kv";
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

    die "subclass must implement 'get'"
}

=head2 set KEY => VALUE, [TYPE]

Sets the value C<VALUE> for C<KEY> for the session.  C<TYPE>, which
defaults to "key", allows values to be set in other namespaces,
including "metadata" and "continuation". C<VALUE> can be an arbitrary
perl data structue -- C<Jifty::Web::Session> will serialize it for
you.

=cut

sub set {
    die "subclass must implement 'set'"
}

=head2 remove KEY, [TYPE]

Remove key C<KEY> from the cache.  C<TYPE> defaults to "key".

=cut

sub remove {
    die "subclass must implement 'remove'"
}

=head2 remove_all

Removes the session from the database entirely.

=cut

sub remove_all {
    die "Subclass must implement 'remove_all'"
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
    die "Subclass must implement 'continuations'";
}

=head2 set_cookie

Sets the session cookie.

=cut

sub set_cookie {
    my $self = shift;

    # never send a cookie with cached content. misbehaving proxies cause
    # terrific problems
    return if Jifty->web->response->header('Expires');

    $self->load unless $self->loaded;

    my $cookie_name = $self->cookie_name;
    my $cookies     = Jifty->web->request ? Jifty->web->request->cookies : {};
    my $cookie      = {
        value   => $self->id,
        path    => '/',
        expires => $self->expires,
    };
    # XXX: do we every need to check the existing cookie to decide if
    # we want to set the cookie this time?
    Jifty->web->response->cookies->{$cookie_name} = $cookie;
}

=head2 cookie_name

Returns the current session's cookie_name -- it is the same for all
users, but varies according to the port the server is running on.

=cut

sub cookie_name {
    my $self        = shift;
    my $cookie_name = $self->{'_cookie_name'};
    my $port        = ( ( Jifty->web->request && Jifty->web->request->port) || 'NOPORT' );
    $cookie_name =~ s/\$PORT/$port/g;
    return ($cookie_name);
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
