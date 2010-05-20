package Jifty::Web::Session::ApacheSession;

=head1 NAME

Jifty::Web::Session::ApacheSession - Jifty Sessions based on Apache::Session

=head1 SYNOPSIS

In your F<etc/config.yml>, using the L<Apache::Session::File> backend:

  framework:
    Web:
      SessionClass: Jifty::Web::Session::ApacheSession
      SessionBackend: File
      SessionOptions:
        Directory: /tmp/sessions
        LockDirectory: /var/lock/sessions

Or with L<Apache::Session::Memorycached> backend:

  framework:
    Web:
      SessionClass: Jifty::Web::Session::ApacheSession
      SessionBackend: Memorycached
      SessionOptions: { servers: [ '127.0.0.1:11211' ] }

=cut

use strict;
use warnings;
use Jifty::Model::Session ();
use base 'Jifty::Web::Session';

=head2 new

Returns a new, empty session handler, subclassing L<Jifty::Web::Session>.

=cut

sub new {
    my $class = shift;
    my $cookie_name = Jifty->config->framework('Web')->{'SessionCookieName'};
    my $backend_class = Jifty->config->framework('Web')->{'SessionBackend'}
        or die "Please set SessionBackend in your framework/Web settings";
    $backend_class = "Apache::Session::$backend_class" unless $backend_class =~ /::/;
    Jifty::Util->require($backend_class);

    return bless { _cookie_name => $cookie_name, _backend_class => $backend_class }, $class;
}

=head2 id

Returns the session's id if it has been loaded, or C<undef> otherwise.

=cut

sub id {
    my $self = shift;
    return $self->loaded ? $self->_session->{_session_id} : undef;
}

=head2 create

Creates a new session.

=cut

sub create {
    my $self = shift;
    my %session;
    my $options = Jifty->config->framework('Web')->{'SessionOptions'};
    tie %session => $self->{_backend_class}, undef, $options;
    $self->{_session} = \%session;
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
        $session_id = $cookies{$cookie_name}
            ? $cookies{$cookie_name}->value()
            : Jifty::Model::Session->new_session_id,
    }

    my $options = Jifty->config->framework('Web')->{'SessionOptions'};

    my %session;
    local $@;
    eval {
        tie %session => $self->{_backend_class}, $session_id, $options;
        1;
    } or do {
        tie %session => $self->{_backend_class}, undef, $options;
    };

    $self->{_session} = \%session;
}

=head2 get KEY [TYPE]

See L<Jifty::Web::Session/get>.

=cut

sub get {
    my $self     = shift;
    my $key      = shift;
    my $key_type = shift || "key";

    return undef unless $self->loaded;
    return $self->_session->{$key_type,$key};
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
    $self->_session->{$key_type,$key} = $value;
}

=head2 remove KEY, [TYPE]

See L<Jifty::Web::Session/remove>.

=cut

sub remove {
    my $self     = shift;
    my $key      = shift;
    my $key_type = shift || "key";

    return undef unless $self->loaded;
    delete $self->_session->{$key_type,$key};
}

=head2 remove_all

See L<Jifty::Web::Session/remove_all>.

=cut

sub remove_all {
    my $self     = shift;

    return undef unless $self->loaded;
    undef %{$self->_session};
}

=head2 continuations

See L<Jifty::Web::Session/continuations>.

=cut

sub continuations {
    my $self     = shift;
    return () unless $self->loaded;

    my $session = $self->_session;
    my %continuations;
    foreach my $key (keys %$session) {
        if ($key =~ /^continuation$;(.*)/os) {
            $continuations{$1} = $session->{$key};
        }
    }
    return %continuations;
}

1;
