use warnings;
use strict;

package Jifty::Web::Session;
use base qw/Jifty::Object Class::Accessor/;
use CGI::Cookie;

# We don't use Class::Accessor as we want to do our own 'set' and 'get' here
#__PACKAGE__->mk_accessors(qw(_session));




=head2 load

Load up the current session from a cookie

=cut


sub load {
    my $self = shift;

    my $m    = Jifty->web->mason;
    return
        if $m
        && $m->is_subrequest;    # avoid reentrancy, as suggested by masonbook
    my $session_class = 'Apache::Session::File';
    my $pm            = "$session_class.pm";
    $pm =~ s|::|/|g;
    require $pm;

    my %cookies       = CGI::Cookie->fetch();
    my $cookiename = $self->cookie_name;
    my $session_id =  $cookies{$cookiename} ? $cookies{$cookiename}->value() : undef;
    
    
    $Storable::Deparse = 1;
    $Storable::Eval    = 1;
    my %session;

    eval {
        tie %session, $session_class,
            ( $session_id ? $session_id : '12' ),
            {
            Directory     => '/tmp',
            LockDirectory => '/tmp'
            };
    };

    if ($@) {

        # If the session is invalid, create a new session.
        if ( $@ =~ /Object does not/i ) {
            tie %session, $session_class, undef,
                {
                Directory     => '/tmp',
                LockDirectory => '/tmp'
                };
            undef $cookies{$self->cookie_name};
        } else {
            $self->log->fatal( "Couldn't store your session:\n", $@ );
            return;
        }
    }

    $self->_session( tied(%session) );


}




sub _session {
    my $self = shift;
    $self->{'_session'} = shift if (@_);
    return ($self->{'_session'});
}

=head2 get KEY

Returns the value for C<KEY> for the current user's session

=cut

sub get {
    my $self = shift;
    my $key = shift;
    return($self->_session ? $self->_session->FETCH($key) : undef);

}


=head2 set KEY => VALUE

Sets the value C<VALUE> for C<KEY> for the current user's session

=cut

sub set {
    my $self = shift;
    my $key = shift;
    my $value = shift;

    ($self->_session ? $self->_session->STORE($key => $value) : undef);

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
    my %continuations;
    # XXX TODO: we're deeply abusing the API. that's uncool. We want to replace Apache::Session
    map { $continuations{$_} = $self->get($_) } grep { /^_continuation_/ } keys %{$self->_session->{'data'}};
    return %continuations;
}





=head2 set_cookie

Sets the session cookie

=cut

sub set_cookie {
    my $self       = shift;
    my $m          = Jifty->web->mason;

    my $cookie_name = $self->cookie_name;
    my %cookies    = CGI::Cookie->fetch();
                my $session_id =  $cookies{$cookie_name} ? $cookies{$cookie_name}->value() : undef;

    if (   ( !$cookies{$cookie_name} ) or ( $self->expires  xor $cookies{$cookie_name}->expires ) ) {   
        my $cookie = new CGI::Cookie(
            -name    => $cookie_name,
            -value   => $self->get('_session_id'),
            -expires => $self->get('_expires'),
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
        if(@_) {
                my $expiry = shift;
        $self->set('_expires' => $expiry);
    }
        return ($self->get('_expires'));
}



1;
