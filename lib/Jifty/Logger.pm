use warnings;
use strict;

package Jifty::Logger;

=head1 NAME

Jifty::Logger -- A master class for Jifty's logging framwork

=head1 DESCRIPTION

Uses C<Log::Log4perl> to log messages.  By default, logs all messages to
the screen.

=cut

use Log::Log4perl;

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
    $SIG{__WARN__} = sub {

        # This caller_depth line tells Log4perl to report
        # the error as coming from on step further up the
        # caller chain (ie, where the warning originated)
        # instead of from the $logger->warn line.
        local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + 1;

        # If the logger has been taken apart by global destruction,
        # don't try to use it to log warnings
        if (Log::Log4perl->initialized) {
            # @_ often has read-only scalars, so we need to break
            # the aliasing so we can remove trailing newlines
            my @lines = map {"$_"} @_;
            $logger->warn(map {chomp; $_} @lines);
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
        my $log_level = Jifty->config->framework('LogLevel');
        my %default = (
            'log4perl.rootLogger'        => "$log_level,Screen",
            '#log4perl.logger.SchemaTool' => "$log_level,Screen",
            'log4perl.appender.Screen'   => 'Log::Log4perl::Appender::Screen',
            'log4perl.appender.Screen.stderr' => 1,
            'log4perl.appender.Screen.layout' =>
                'Log::Log4perl::Layout::SimpleLayout'
        );
        Log::Log4perl->init( \%default );
  }
}

=head1 AUTHOR

Various folks at Best Practical Solutions, LLC.

=cut

1;
