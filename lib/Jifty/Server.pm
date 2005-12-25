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
use base qw/HTTP::Server::Simple::Mason/;
use base qw/Class::Accessor/;
use base qw/Jifty::Object/;
use File::Spec;
use Module::Refresh;
use Log::Log4perl;
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

=head2 mason_config

The Jifty standalone server gets its Mason configuration from the same place that any other
Jifty handler does: C<< Jifty::Handler->mason_config >>.

=cut

sub mason_config { Jifty::Handler->mason_config } 

=head2 handle_error

Overrides L<HTTP::Server::Simple::Mason>'s handle_error method to
return an error to the browser, and log an error using Log::Log4perl

=cut

sub handle_error {
    my $self = shift;
    my $error = shift;
   
    # Report error as coming from the appropriate place
    $Log::Log4perl::caller_depth++;
    my $logger = Log::Log4perl::get_logger("");
    my $time = Log::Log4perl::DateFormat->new("yyyy/MM/dd HH:mm:ss")->format(time); 
    my $escaped_error = $error;
    $escaped_error =~ s/</&lt;/gi;

    warn "THIS IS UNSAFE ESCAPING";

    print <<"EOF";
<html>
    <head><title>Internal Error</title></head>
    <body>
    <h1>Internal error</h1>
    <p>Something bad happened inside the server. Generally, this indicates something like a programming error or a broken database.</p>
    <pre>@{[ $escaped_error ]}</pre>
    </body>
</html>
EOF

    $logger->logdie($error);
}


=head2 setup_jifty

Sets up the Jifty singleton.  This is called automatically by L</new>.

=cut

sub setup_jifty {
    my $self = shift;
    my %args = (
        @_
    );

    $self->port( Jifty->config->framework('Web')->{'Port'}
          || 8888 );
}

=head2 handle_request

Overrives L<HTML::Server::Simple::Mason>'s handle_request method to
make use of L<Module::Refresh> to refresh any relevant modules, as
well as to set up the C<$JiftyWeb> global before handling the actual
request.

=cut

sub handle_request {
    my $self = shift;

    Module::Refresh->refresh;

    local $HTML::Mason::Commands::JiftyWeb = Jifty::Web->new();
     $self->SUPER::handle_request(@_); 
    Jifty::Handler->cleanup_request();
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
    unshift @ISA, "HTTP::Server::Simple::Recorder" unless UNIVERSAL::isa($class, 'HTTP::Server::Simple::Recorder');
} 

1;

