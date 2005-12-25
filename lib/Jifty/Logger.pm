use warnings;
use strict;

package Jifty::Logger;

=head1 NAME

Jifty::Logger -- A master class for Jifty's logging framwork

=head1 DESCRIPTION

Uses L<Log4Perl> to log messages.  By default, logs all messages to
the screen.

=cut

use Log::Log4perl;

use base qw/Jifty::Object/;

=head1 METHODS

=head2 new COMPONENT

This class method instantiates a new C<Jifty::Logger> object. This
object deals with logging for the system.

Takes an optional name for this Jifty's logging "component" - See
L<Log4Perl> for some detail about what that is.  It sets up a "warn"
handler which logs warnings to the specified component.

=cut

sub new {
    my $class     = shift;
    my $component = shift;

    my $self = {};
    bless $self, $class;

    $component = '' unless defined $component;

    my $log_config
        = Jifty::Util->absolute_path( Jifty->config->framework('LogConfig') );
    if (not Log::Log4perl->initialized) {
        if ( defined Jifty->config->framework('LogReload') ) {
            Log::Log4perl->init_and_watch( $log_config,
                Jifty->config->framework('LogReload') );
        } elsif ( -f $log_config and -r $log_config ) {
            Log::Log4perl->init($log_config);
        } else {
            my %default = (
                'log4perl.rootLogger'        => "ALL,Screen",
                '#log4perl.logger.SchemaTool' => "INFO,Screen",
                'log4perl.appender.Screen'   => 'Log::Log4perl::Appender::Screen',
                'log4perl.appender.Screen.stderr' => 1,
                'log4perl.appender.Screen.layout' =>
                    'Log::Log4perl::Layout::SimpleLayout'
            );
            Log::Log4perl->init( \%default );
        }
    }
    my $logger = Log::Log4perl->get_logger($component);
    $SIG{__WARN__} = sub {

        # This caller_depth line tells Log4perl to report
        # the error as coming from on step further up the
        # caller chain (ie, where the warning originated)
        # instead of from the $logger->warn line.
        local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + 1;

        # If the logger has been taken apart by global destruction,
        # don't try to use it to log warnings
        $logger->warn(@_) if Log::Log4perl->initialized;
    };

    return $self;
}

=head1 AUTHOR

Various folks at Best Practical Solutions, LLC.

=cut

1;
