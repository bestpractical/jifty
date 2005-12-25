use warnings;
use strict;

package Jifty::Web::Session;
use base qw/Jifty::Object Class::Accessor/;
use Cache::FileCache;

use vars qw/$CACHE/;
$CACHE = Cache::FileCache->new();

sub _cache {
    return $CACHE;
}



=head2 load

Load up the current session from a cookie

=cut


sub load {
    my $self = shift;
    $self->set_cookie();

}

=head2 session_hashref

Returns a hashref of all the keys in this session

=cut

sub session_hashref {
        my $self = shift;
    return $self->_cache->get($self->session_id);
}

=head2 get KEY

Returns the value for C<KEY> for the current user's session

=cut

sub get {
    my $self = shift;
    my $key = shift;
    return(($self->session_hashref||{})->{$key});

}


=head2 set KEY => VALUE

Sets the value C<VALUE> for C<KEY> for the current user's session

=cut

sub set {
    my $self = shift;
    my $key = shift;
    my $value = shift;

    my $cache = $self->session_hashref();
    $cache->{$key} = $value;
    $self->_cache->set($self->session_id => $cache);

}


=head2 remove KEY

Remove key C<KEY> from the cache.

=cut

sub remove {
    my $self = shift;
    my $key = shift;
    $self->set($key => undef);
}


=head2 set_continuation KEY VALUE

Stores a continuation in the session

=cut


sub set_continuation {
    my $self = shift;
    my $key = shift;
    my $val = shift;

    $self->set( '_continuation_'.$key => $val);

}



=head2 get_continuation KEY 

Pulls a continuation from the current session. Expects a continuation id

=cut

sub get_continuation { 
    my $self = shift;
    my $key = shift;
    $self->get('_continuation_'.$key);

}

=head2 remove_continuation CONTINUATION_ID

Removes a continuation with id CONTINUATION id from the store.

=cut

sub remove_continuation {
    my $self = shift;
    my $key = shift;
    $self->remove('_continuation_'.$key);
}


=head2 continuations

Return a hash of all the continuations in this session. Keyed by continuation_C<id>.

=cut


sub continuations {
    my $self = shift;
    my $session = $self->session_hashref;
    my %continuations;
    map { $continuations{$_} = $session->{$_} } grep { /^_continuation_/ } keys %$session;
    return %continuations;
}


=head2 session_id

Returns the JIFTY_SID_C<PORTNUM>.

=cut

sub session_id {
    my $self = shift;
    return $self->{_session_id} if ($self->{_session_id});
    my %cookies       = CGI::Cookie->fetch();
    my $cookiename = $self->cookie_name;
    my $session_id =  $cookies{$cookiename} ? $cookies{$cookiename}->value() : $self->new_session_id;
    $self->{_session_id} = $session_id;
    return ($session_id);
}



=head2 new_session_id

Get a new session id, stuff it in a cookie and send it to the browser

=cut

sub new_session_id { 
    my $self = shift;
    my $digest = Digest::MD5->new();
    $digest->add( Jifty->web->serial);
    $digest->add($$);
    $digest->add(rand(10));
    
    return ($digest->b64digest);
}

=head2 set_cookie

Sets the session cookie

=cut

sub set_cookie {
    my $self       = shift;
    my $m          = Jifty->web->mason;

    my $cookie_name = $self->cookie_name;
    my %cookies    = CGI::Cookie->fetch();
    if (   ( !$cookies{$cookie_name} ) or ( $self->expires  xor $cookies{$cookie_name}->expires ) ) {   
        my $cookie = new CGI::Cookie(
            -name    => $cookie_name,
            -value   => $self->session_id,
            -expires => $self->expires,
        );

        # XXX TODO might need to change under mod_perl
        $m->cgi_request->headers_out->{'Set-Cookie'} = $cookie->as_string if ($m);
    }
}


=head2 cookie_name

Returns the current session's cookie_name. (It's a generic thing for all users

=cut

sub cookie_name {
    my $self = shift;
    my $cookiename = "JIFTY_SID_" . ( $ENV{'SERVER_PORT'} || 'NOPORT' );
    return ($cookiename);

}

=head2 expires

Return this cache entry's expirey date, in the format expected by Cache::Cache;

=cut


sub expires {
        my $self = shift;
        $self->{'_expires'} = shift if (@_);
        return ($self->{'_expires'} || '');
}



1;
