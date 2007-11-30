#!/usr/bin/env perl
package Jifty::Plugin::Recorder::Command::Playback;

# note that you'll need a patch to App::CLI to allow arbitrary
# files to define new commands

package Jifty::Script::Playback;
use strict;
use warnings;

use base qw/App::CLI::Command/;
use Time::HiRes 'sleep';

=head1 Jifty::Script::Playback - Play back a request log

=head1 DESCRIPTION

L<Jifty::Plugin::Recorder> lets you record a request log. Using this command
you can play back the request log. This can be handy for performance testing
and debugging, and perhaps even testing.

=head1 API

=head2 options

This command takes three options. Any arguments that are not options will be
interpreted as files to play back. Files will be played back in the order they
are given on the command line.

=over 4

=item max

The maximum time to wait between requests. By default there is no maximum and
requests will be made exactly as they are in the log.

=item quiet

Suppress TRACE, DEBUG, and INFO log levels.

=item dbiprof

Enable DBI profiling.

=back

=cut

sub options {
    (
     'max=s'    => 'max',
     'quiet'    => 'quiet',
     'dbiprof'  => 'dbiprof',
    )
}

=head2 run

Run takes no arguments. It goes through most of the motions of starting a
server, except it won't let the server accept incoming requests. It will then
start playing back the request logs. Once finished, it will exit normally.

=cut

sub run {
    my $self = shift;
    Jifty->new();

    # Purge stale mason cache data
    my $data_dir = Jifty->config->framework('Web')->{'DataDir'};
    my $server_class = Jifty->config->framework('Web')->{'ServerClass'} || 'Jifty::Server';
    Jifty::Util->require($server_class);

    if (-d $data_dir) {
        File::Path::rmtree(["$data_dir/cache", "$data_dir/obj"]);
    }
    else {
        File::Path::mkpath([$data_dir]);
    }

    Jifty->handle->dbh->{Profile} = '6/DBI::ProfileDumper'
        if $self->{dbiprof};

    Log::Log4perl->get_logger($server_class)->less_logging(3)
        if $self->{quiet};

    $server_class->new();
    # we're not calling $server_class->run because we don't want any other
    # requests to come in during the playback. but we do want the server
    # to be around.

    # now read in the YAML and do our dark deeds
    for my $file (@ARGV) {
        my @requests = YAML::LoadFile($file);
        $self->play_requests(@requests);
    }
}

=head2 play_request REQUEST

Plays back a single request, right now, through Jifty->handler. It expects
C<< $request->{ENV} >> to be a hashref which will set C<%ENV>. It expects
C<< $request->{cgi} >> to be a CGI object which will be passed to
C<< Jifty->handler->handle_request >>.

=cut

sub play_request {
    my $self    = shift;
    my $request = shift;

    # XXX: the output should go to a file for testability, and to suppress
    # the "print on closed filehandle" warnings
    close STDOUT;

    %ENV = %{ $request->{ENV} };
    Jifty->handler->handle_request(cgi => $request->{cgi});
}

=head2 play_requests REQUESTs

Plays through a list of requests, sleeping between each. Each request should be
a hashref with fields C<time> (a possibly fractional number of seconds,
representing the time of the request, relative to when the server started);
C<ENV> (used to set C<%ENV>); and C<cgi> (passed to
Jifty->handler->handle_request).

=cut

sub play_requests {
    my $self = shift;

    my $current_time = 0;
    for my $request (@_) {
        $request->{time} -= $current_time;
        $request->{time} = $self->{max}
            if defined($self->{max}) && $request->{time} > $self->{max};

        Jifty->log->info("Next request in $request->{time} seconds.");
        sleep $request->{time};
        $current_time += $request->{time};

        $self->play_request($request);
    }
}

=head2 filename

This is used as a hack to get L<App::CLI> to retrieve our POD correctly.

Inner packages are not given in C<%INC>. If anyone finds a way around this,
please let us know.

=cut

sub filename { __FILE__ }

1;

