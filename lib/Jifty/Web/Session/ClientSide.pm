package Jifty::Web::Session::ClientSide;

=head1 NAME

Jifty::Web::Session::ClientSide - Session handler for client-side sessions

=head1 SYNOPSIS

In your F<etc/config.yml>:

  framework:
    Web:
      SessionClass: Jifty::Web::Session::ClientSide
      SessionSecret: secret_passphrase

=cut

use strict;
use warnings;
use base 'Jifty::Web::Session';
use Jifty::Model::Session();
use Storable ();
use Compress::Zlib ();
use Crypt::CBC ();
use Crypt::Rijndael ();
use CGI::Cookie::Splitter ();
use MIME::Base64;

my $session_key;
my $splitter = CGI::Cookie::Splitter->new;

=head2 new

Returns a new, empty session handler, subclassing L<Jifty::Web::Session>.

=cut

sub new {
    my $class = shift;
    my $cookie_name = Jifty->config->framework('Web')->{'SessionCookieName'};
    my $session_key = Jifty->config->framework('Web')->{'SessionSecret'}
        or die "Please set SessionSecret in your framework/Web settings";
    my $cipher = Crypt::CBC->new(
        -key    => $session_key,
        -cipher => 'Rijndael',
    );
    bless { _cookie_name => $cookie_name, _cipher => $cipher, _session => undef }, $class;
}

=head2 _cipher

Accessor to the underlying L<Crypt::CBC> object that encapsulates the
server-side secret.

=cut

sub _cipher {
    my $self = shift;
    $self->{'_cipher'} = shift if (@_);
    return ( $self->{'_cipher'} );
}

=head2 id

Returns the session's id if it has been loaded, or C<undef> otherwise.

=cut

sub id {
    my $self = shift;
    return $self->loaded ? $self->_session->{session_id} : undef;
}

=head2 load [ID]

Load up the current session from the given C<ID>, or the appropriate
cookie (see L<Jifty::Web::Session/cookie_name>) otherwise.

If both of those fail, creates a session in memory.

=cut

sub load {
    my $self       = shift;
    my $session_id = shift;
    my %cookies    = CGI::Cookie->fetch();

    unless ($session_id) {
        my $cookie_name = $self->cookie_name;
        $session_id = $cookies{$cookie_name}->value() if $cookies{$cookie_name};
        $session_id ||= Jifty::Model::Session->new_session_id;
    }


    my $data;

    {
        local $@;
        eval {
            ($data) = grep {
                $_->name eq "JIFTY_DAT_$session_id"
            } $splitter->join(values %cookies);
        };

        if ($@) {
            # Reassembly of cookie failed -- start a new session
            $session_id = Jifty::Model::Session->new_session_id;
            warn $@;
        }
    }

    if ($data) {
        local $@;
        eval {
            local $Storable::Eval = 0; # Just to be on the safe side...

            if (my $session = Storable::thaw(
                Compress::Zlib::uncompress(
                    $self->_cipher->decrypt(
                        decode_base64(
                            $data->value
                        )
                    )
                )
            )) {
                $self->_session($session);
                die "Session id mismatch"
                    unless $self->_session->{session_id} eq $session_id;
            }
            1;
        } and return;
        warn $@ if $@;
    }

    $self->_session({
        session_id   => $session_id,
        continuation => {},
        metadata     => {},
        key          => {},
    });
}

=head2 get KEY [TYPE]

See L<Jifty::Web::Session/get>.

=cut

sub get {
    my $self     = shift;
    my $key      = shift;
    my $key_type = shift || "key";

    return undef unless $self->loaded;
    return $self->_session->{$key_type}{$key};
}

=head2 set KEY => VALUE, [TYPE]

See L<Jifty::Web::Session/set>.

=cut

sub set {
    my $self     = shift;
    my $key      = shift;
    my $value    = shift;
    my $key_type = shift || "key";

    return undef unless $self->loaded;
    $self->_session->{$key_type}{$key} = $value;

    # XXX - delay until the very last moment?
    $self->flush;
}

=head2 remove KEY, [TYPE]

See L<Jifty::Web::Session/remove>.

=cut

sub remove {
    my $self     = shift;
    my $key      = shift;
    my $key_type = shift || "key";

    return undef unless $self->loaded;
    delete $self->_session->{$key_type}{$key};
}

=head2 continuations

See L<Jifty::Web::Session/continuations>.

=cut

sub continuations {
    my $self     = shift;
    return () unless $self->loaded;
    return %{ $self->_session->{continuation} };
}

=head2 unload

See L<Jifty::Web::Session/unload>.

=cut

sub unload {
    my $self = shift;
    $self->flush;
    $self->_session(undef);
}

=head2 flush

Outputs the client-side session as one or more cookies.

=cut

sub flush {
    my $self = shift;
    my $session_id = $self->id or return;

    my $data_cookie = CGI::Cookie->new(
        -name    => "JIFTY_DAT_$session_id",
        -expires => $self->expires,
        -value   => encode_base64(
            $self->_cipher->encrypt(
                Compress::Zlib::compress(
                    Storable::nfreeze(
                        $self->_session
                    )
                )
            )
        )
    );

    foreach my $cookie ($splitter->split( $data_cookie )) {
        Jifty->web->response->cookies->{$cookie->name} = $cookie;
    }
}

1;
