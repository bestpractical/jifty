use strict;
use warnings;

package Jifty::Plugin::LeakDetector;
use base qw/Jifty::Plugin Class::Data::Inheritable/;
use Data::Dumper;
use Devel::Events::Handler::ObjectTracker;
use Devel::Events::Generator::Objects;
use Devel::Size 'total_size';

our $VERSION = 0.01;

__PACKAGE__->mk_accessors(qw(tracker generator));
our @requests;

my $empty_array = total_size([]);

sub init {
    my $self = shift;
    return if $self->_pre_init;

    Jifty::Handler->add_trigger(
        before_request => sub { $self->before_request(@_) }
    );

    Jifty::Handler->add_trigger(
        after_request  => sub { $self->after_request(@_) }
    );
}

sub before_request
{
    my $self = shift;
    $self->tracker(Devel::Events::Handler::ObjectTracker->new());
    $self->generator(
        Devel::Events::Generator::Objects->new(handler => $self->tracker)
    );

    $self->generator->enable();
}

sub after_request
{
    my $self = shift;
    my $handler = shift;
    my $cgi = shift;

    $self->generator->disable();

    my $leaked = $self->tracker->live_objects;
    my $leaks = keys %$leaked;

    # XXX: Devel::Size seems to segfault Jifty at END time
    my $size = total_size([ keys %$leaked ]) - $empty_array;

    push @requests, {
        id => 1 + @requests,
        url => $cgi->url(-absolute=>1,-path_info=>1),
        size => $size,
        objects => Dumper($leaked),
        time => scalar gmtime,
        leaks => $leaks,
    };

    $self->generator(undef);
    $self->tracker(undef);
}

=head1 NAME

Jifty::Plugin::LeakDetector

=head1 DESCRIPTION

Memory leak detection and reporting for your Jifty app

=head1 USAGE

Add the following to your site_config.yml

 framework:
   Plugins:
     - LeakDetector: {}

This makes the following URLs available:

View the top-level leak report (how much each request has leaked)

    http://your.app/leaks

View an individual request's detailed leak report (which objects were leaked)

    http://your.app/leaks/3

=cut

1;

