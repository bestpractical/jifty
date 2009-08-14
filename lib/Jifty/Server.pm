use warnings;
use strict;

package Jifty::Server;

=head1 NAME

Jifty::Server - Stand-alone server implementation for Jifty

=head1 SYNOPSIS

  use Jifty::Server;
  my $server = Jifty::Server->new();
  $server->run();

=head1 DESCRIPTION

C<Jifty::Server> is a subclass of L<HTTP::Server::Simple> which
creates a handy standalone web server for a lightweight Jifty application.

=cut


use base qw/HTTP::Server::Simple::CGI Jifty::Object/;
use File::Spec;
use Log::Log4perl;
use HTTP::Server::Simple;
use HTTP::Server::Simple::Recorder;

=head1 METHODS

=head2 new

Creates a new C<Jifty::Server> object.

=cut

sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;
    $self->setup_jifty(@_);
    $self->recording_on if $ENV{'JIFTY_RECORD'};

    return ($self);
}

=head2 setup_jifty

Sets up the Jifty singleton.  This is called automatically by L</new>.

=cut

sub setup_jifty {
    my $self = shift;
    my %args = (
        port => undef,
        @_
    );

    Jifty->config->framework('Web')->{'Port'} = $args{port} if $args{port};
    $self->port( Jifty->config->framework('Web')->{'Port'} || 8888 );
}

=head2 handle_request CGI

Calls L<Jifty::Handler/handle_request> with the CGI object.  If
running tests, send test warnings on specific requests.

=cut

sub handle_request {
    my $self = shift;
    my $cgi = shift;

    Jifty->handler->handle_request( cgi  => $cgi );
}

=head2 print_banner

Overrives L<HTML::Server::Simple::Mason>'s print_banner to use the
logging framework to record the server's startup

=cut

sub print_banner {
    my $self = shift;
    $self->log->info("You can connect to your server at ", Jifty::Web->url);
} 

=head2 recorder_prefix

Returns the filename prefix used if L<HTTP::Server::Simple::Recorder> support is being used.

=cut

sub recorder_prefix {
    # XXX TODO FIXME get from config
    Jifty::Util->absolute_path("log/recorded/jifty-recorded.$$")
} 

=head2 recording_on

Sets this server to use L<HTTP::Server::Simple::Recorder>.

(See also the C<JIFTY_RECORD> environment variable and the C<-r> switch to C<standalone_server>.)

=cut

sub recording_on {
    my $class = shift;
    our @ISA;
    unshift @ISA, "HTTP::Server::Simple::Recorder" unless $class->isa('HTTP::Server::Simple::Recorder');
}

=head2 after_setup_listener

If C<$ENV{JIFTY_SERVER_SIGREADY}> is set, send the signal to the
parent when the server is ready for requests.

=cut

sub after_setup_listener {
    my $self = shift;

    my $sig = $ENV{JIFTY_SERVER_SIGREADY} or return;
    kill $sig => getppid();
}

=head2 restart

Sets up the arguments needed for restarting the server using C<jifty server>.

=cut

sub restart {
    my $self = shift;
    local @ARGV = ( 'server', '--restart' );
    $self->SUPER::restart;
}

=head2 close_client_sockets

Closes all active client connections.

=cut

sub close_client_sockets {
    my $self = shift;
    close STDOUT;
    close STDIN;
    if ($self->{net_server}) {
        close $self->{net_server}{server}{client};
    } else {
        close $self->{_stdio_handle};
    }
}

=head2 started_ok

After starting, ensure we have a different database socket from the
server.

=cut

sub started_ok {
    my $self = shift;
    my $ret = $self->SUPER::started_ok(@_);
    if ($ret) {
        Jifty->handle->dbh->{InactiveDestroy} = 1;
        Jifty->setup_database_connection;
    }
    return $ret;
}

1;

