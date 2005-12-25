use warnings;
use strict;

package JFDI::Server;

=head1 NAME

JFDI::Server - Standalone web server for JFDI applications

=head1 SYNOPSIS

  use JFDI::Server;
  my $app = JFDI->new( ... );
  my $server = JFDI::Server->new(application => $app);
  $server->run();

=head1 DESCRIPTION

C<JFDI::Server> is a subclass of L<HTML::Server::Simple::Mason> which
creates a handy standalone testbed for a JFDI application.

=cut

use JFDI::Everything;
use base qw/HTTP::Server::Simple::Mason/;
use base qw/Class::Accessor/;
use base qw/JFDI::Object/;
use File::Spec;
use FindBin;
use Module::Refresh;
use Log::Log4perl;
use HTTP::Server::Simple::Recorder;

=head1 METHODS

=head2 new

Creates a new C<JFDI::Server> object.

=cut

sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;

    $self->setup_jfdi(@_);

    $self->recording_on if $ENV{'JFDI_RECORD'};

    return ($self);

}

=head2 mason_config

The JFDI standalone server gets its Mason configuration from the same place that any other
JFDI handler does: C<< JFDI::Handler->mason_config >>.

=cut

sub mason_config { JFDI::Handler->mason_config } 

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


=head2 setup_jfdi

Sets up the JFDI singleton.  This is called automatically by L</new>.

=cut

sub setup_jfdi {
    my $self = shift;
    my %args = (
        @_
    );

    $self->port( JFDI->framework_config('Web')->{'Port'}
          || 8888 );
}

=head2 handle_request

Overrives L<HTML::Server::Simple::Mason>'s handle_request method to
make use of L<Module::Refresh> to refresh any relevant modules, as
well as to set up the C<$framework> global before handling the actual
request.

=cut

sub handle_request {
    my $self = shift;

    Module::Refresh->refresh;

    $HTML::Mason::Commands::framework = JFDI::Web->new();
     $self->SUPER::handle_request(@_); 
    JFDI::Handler->cleanup_request();
    undef $HTML::Mason::Commands::framework;
}


=head2 print_banner

Overrives L<HTML::Server::Simple::Mason>'s print_banner to use the
logging framework to record the server's startup

=cut

sub print_banner {
    my $self = shift;

    $self->log->info("You can connect to your server at http://localhost:", $self->port, "/");
} 

=head2 recorder_prefix

Returns the filename prefix used if L<HTTP::Server::Simple::Recorder> support is being used.

=cut

sub recorder_prefix {
    # XXX TODO FIXME get from config
    JFDI->absolute_path("log/recorded/jfdi-recorded.$$")
} 

=head2 recording_on

Sets this server to use L<HTTP::Server::Simple::Recorder>.

(See also the C<JFDI_RECORD> environment variable and the C<-r> switch to C<standalone_server>.)

=cut

sub recording_on {
    my $class = shift;
    our @ISA;
    unshift @ISA, "HTTP::Server::Simple::Recorder" unless UNIVERSAL::isa($class, 'HTTP::Server::Simple::Recorder');
} 

1;

