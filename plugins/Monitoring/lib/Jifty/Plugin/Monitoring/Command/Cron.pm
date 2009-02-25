use strict;
use warnings;

package Jifty::Plugin::Monitoring::Command::Cron;

# note that you'll need a patch to App::CLI to allow arbitrary
# files to define new commands

package Jifty::Script::Cron;

use base qw/App::CLI::Command/;

=head1 NAME

Jifty::Script::Cron - Runs any monitoring services

=head1 SYNOPSIS

If your app uses L<Jifty::Plugin::Monitoring>, this script should be
run by your cron daemon.  The frequency it should be run is
determinded by the LCM of the monitors you have scheduled.  Running it
more frequently that this is not harmful, except by consuming come
resources.

=head1 DESCRIPTION

=head2 options

Takes no options.

=head2 run

Examines the application, looking for an instance of the monitoring
plugin, and runs it.

=cut

sub run {
    my $self = shift;
    Jifty->new;

    my ($monitor) = Jifty->find_plugin('Jifty::Plugin::Monitoring');
    die "Monitoring is not enabled for @{[Jifty->app_class]}\n" unless $monitor;
    $monitor->run_monitors;
}

=head2 filename

This is used as a hack to get L<App::CLI> to retrieve our POD correctly.

Inner packages are not given in C<%INC>. If anyone finds a way around this,
please let us know.

=cut

sub filename { __FILE__ }

=head1 SEE ALSO

L<Jifty::Plugin::Monitoring>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Best Practical Solutions

This is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
