package Jifty::Logger::EventAppender;
use strict;
use warnings;
use base qw/Log::Log4perl::Appender/;

# We need to pull these in explicitly because this appender class
# could be used from programs which aren't Jifty
use Jifty::Util;
use Jifty;
BEGIN {Jifty->new}

=head1 NAME

Jifty::Logger::EventAppender - Create Jifty events from log directives

=head1 SYNOPSIS

In a log4perl config file:

    log4perl.appender.Event=Jifty::Logger::EventAppender
    log4perl.appender.Event.class=YourApp::Event::Log
    log4perl.appender.Event.arbitraryData=42
    log4perl.appender.Event.layout=SimpleLayout

=head1 DESCRIPTION

This class is a L<Log::Log4perl>-compatible appender which creates
L<Jifty::Event::Log> objects when a logging instruction is received.

=head1 METHODS

=head2 new PARAMHASH

The C<class> configuration parameter controls the class of the event
to create.  It defaults to L<Jifty::Event::Log>.  All other parameters
are passed through to the event when it is created.

=cut

sub new {
    my $class = shift;
    my %params = (
        class => "Jifty::Event::Log",
        @_,
    );

    my $event_class = delete $params{class};
    Jifty::Util->require($event_class) or die "Can't find event class $event_class";

    return bless {params => \%params, class => $event_class}, $class;
}

=head2 log PARAMHASH

Creates an instance of the event with all of the configuration
parameters set in the log4perl config file, as well as all of the
contents of the C<PARAMHASH> -- see L<Log::Log4perl::Appender> for
details of the arguments therein.

=cut

sub log {
    my $self = shift;
    $self->{class}->new( { %{$self->{params}}, @_ } )->publish;
}

1;
