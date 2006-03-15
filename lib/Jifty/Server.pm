use warnings;
use strict;

package Jifty::Server;

=head1 NAME

Jifty::Server - Standalone web server for Jifty applications

=head1 SYNOPSIS

  use Jifty::Server;
  my $server = Jifty::Server->new();
  $server->run();

=head1 DESCRIPTION

C<Jifty::Server> is a subclass of L<HTTP::Server::Simple::Mason> which
creates a handy standalone web server for a lightweight Jifty application.

=cut

use Jifty::Everything;
use base qw/HTTP::Server::Simple::CGI/;
use base qw/Jifty::Object/;
use File::Spec;
use Module::Refresh;
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

    use Hook::LexWrap;
    wrap 'HTML::Mason::FakeApache::send_http_header', pre => sub {
        my $r = shift;
        my $status = $r->header_out('Status') || '200 Jifty OK';
        print STDOUT "HTTP/1.0 $status\n";
    };

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

=head2 handle_request

Overrives L<HTML::Server::Simple::Mason>'s handle_request method to
make use of L<Module::Refresh> to refresh any relevant modules, as
well as to set up the C<$JiftyWeb> global before handling the actual
request.

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
    $self->log->info("You can connect to your server at ", Jifty::Web->url, "/");
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

1;

