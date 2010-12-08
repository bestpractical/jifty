use warnings;
use strict;

package Jifty::Logger;

=head1 NAME

Jifty::Logger -- A master class for Jifty's logging framework

=head1 DESCRIPTION

Jifty uses the Log4perl module to log error messages. In Jifty
programs there's two ways you can get something logged:

Firstly, Jifty::Logger captures all standard warnings that Perl
emits.  So in addition to everything output from perl via the 
warnings pragmas, you can also log messages like so:

    warn("The WHAM is overheating!");

This doesn't give you much control however.  The second way
allows you to specify the level that you want logging to
occur at:

    Jifty->log->debug("Checking the WHAM");
    Jifty->log->info("Potential WHAM problem detected");
    Jifty->log->warn("The WHAM is overheating");
    Jifty->log->error("PANIC!");
    Jifty->log->fatal("Someone call Eddie Murphy!");

=head2 Configuring Log4perl

Unless you specify otherwise in the configuration file, Jifty will
supply a default Log4perl configuration.

The default log configuration that logs all messages to the screen
(i.e. to STDERR, be that directly to the terminal or to the FastCGI
log file.)  It will log all messages of equal or higher priority
to the LogLevel configuration option.

    --- 
    framework: 
      LogLevel: DEBUG

You can tell Jifty to use an entirely different Logging
configuration by specifying the filename of a standard Log4perl
config file in the LogConfig config option (see L<Log::Log4perl> for
the format of this config file.)

    --- 
    framework: 
      LogConfig: etc/log4perl.conf

Note that specifying your own config file prevents the LogLevel
config option from having any effect.

You can tell Log4perl to check that file periodically for changes.
This costs you a little in application performance, but allows
you to change the logging level of a running application.  You
need to set LogReload to the frequency, in seconds, that the
file should be checked.

    --- 
    framework: 
      LogConfig: etc/log4perl.conf
      LogReload: 10

(This is implemented with Log4perl's init_and_watch functionality)

=cut

use Log::Log4perl;
use Carp;

use base qw/Jifty::Object/;

=head1 METHODS

=head2 new COMPONENT

This class method instantiates a new C<Jifty::Logger> object. This
object deals with logging for the system.

Takes an optional name for this Jifty's logging "component" - See
L<Log::Log4perl> for some detail about what that is.  It sets up a "warn"
handler which logs warnings to the specified component.

=cut

sub new {
    my $class     = shift;
    my $component = shift;

    my $self = {};
    bless $self, $class;

    $component = '' unless defined $component;

    # configure Log::Log4perl unless we've done it already
    if (not Log::Log4perl->initialized) {
       $class->_initialize_log4perl;
    }
    
    # create a log4perl object that answers to this component name
    my $logger = Log::Log4perl->get_logger($component);
    
    # whenever Perl wants to warn something out capture it with a signal
    # handler and pass it to log4perl
    my $previous_warning_handler = $SIG{__WARN__};
    $SIG{__WARN__} = sub {

        # This caller_depth line tells Log4perl to report
        # the error as coming from on step further up the
        # caller chain (i.e., where the warning originated)
        # instead of from the $logger->warn line.
        local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + 1;

        # If the logger has been taken apart by global destruction,
        # don't try to use it to log warnings
        if (Log::Log4perl->initialized) {
            my $action = $self->_warning_action(@_);
            # @_ often has read-only scalars, so we need to break
            # the aliasing so we can remove trailing newlines
            my @lines = map {"$_"} @_;
            $logger->$action(map {chomp; $_} @lines);
        }
        elsif ($previous_warning_handler) {
            # Fallback to the old handler
            goto &$previous_warning_handler;
        }
        else {
            # Now handler - just carp about it for now
            local $SIG{__WARN__};
            carp(@_);
        }
    };

    return $self;
}

sub _initialize_log4perl {
    my $class = shift;
  
    my $log_config
        = Jifty::Util->absolute_path( Jifty->config->framework('LogConfig') );

    if ( defined Jifty->config->framework('LogReload') ) {
        Log::Log4perl->init_and_watch( $log_config,
            Jifty->config->framework('LogReload') );
    } elsif ( -f $log_config and -r $log_config ) {
        Log::Log4perl->init($log_config);
    } else {
        my $log_level = uc Jifty->config->framework('LogLevel');
        my %default = (
            'log4perl.rootLogger'        => "$log_level,Screen",
            'log4perl.appender.Screen'   => 'Log::Log4perl::Appender::Screen',
            'log4perl.appender.Screen.stderr' => 1,
            'log4perl.appender.Screen.layout' =>
                'Log::Log4perl::Layout::SimpleLayout'
        );
        Log::Log4perl->init( \%default );
  }
}

=head2 _warning_action

change the Log4Perl action from warn to error|info|etc based 
on the content of the warning.  

Added because DBD::Pg throws up NOTICE and other messages
as warns, and we really want those to be info (or error, depending
on the code).  List based on Postgres documentation

TODO: needs to be smarter than just string matching

returns a valid Log::Log4Perl action, if nothing matches
will return the default of warn since we're in a __WARN__ handler

=cut

sub _warning_action {
    my $self = shift;
    my $warnings = join('',@_);

    my %pg_notices = ('DEBUG\d+' => 'debug',
                      'INFO'     => 'info',
                      'NOTICE'   => 'info',
                      '.*ERROR.*database .* does not exist' => 'info',
                      '.*couldn.t execute the query .DROP DATABASE.' => 'info',
                      'WARNING'  => 'warn',
                      'DBD::Pg.+ERROR'    => 'error',
                      'LOG'      => 'warn',
                      'FATAL'    => 'fatal',
                      'PANIC'    => 'fatal' );
    
    foreach my $notice (keys %pg_notices) {
        if ($warnings =~ /^$notice/) {
            return $pg_notices{$notice};
        } 
    }
    return 'warn';
}

=head1 AUTHOR

Various folks at Best Practical Solutions, LLC.

Mark Fowler <mark@twoshortplanks.com> fiddled a bit.

=cut

1;
