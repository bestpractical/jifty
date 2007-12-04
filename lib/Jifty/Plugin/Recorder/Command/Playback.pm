#!/usr/bin/env perl
package Jifty::Plugin::Recorder::Command::Playback;

# note that you'll need a patch to App::CLI to allow arbitrary
# files to define new commands

package Jifty::Script::Playback;
use strict;
use warnings;

use base qw/App::CLI::Command/;
use Time::HiRes 'sleep';
use Storable 'thaw';

our $start = time; # for naming log files
our $path = 'log/playback';

=head1 Jifty::Script::Playback - Play back request logs

=head1 DESCRIPTION

L<Jifty::Plugin::Recorder> lets you record a request log. Using this command
you can play back request logs. This can be handy for performance tuning,
debugging, and testing.

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
    my $file_num = 0;
    Jifty::Util->make_path($path.'/'.$start);
    for my $file (@ARGV) {
        my @requests = YAML::LoadFile($file);
        $self->play_requests(++$file_num, @requests);
    }
}

=head2 play_request REQUEST

Plays back a single request, right now, through Jifty->handler. It expects
C<< $request->{ENV} >> to be a hashref which will set C<%ENV>. It expects
C<< $request->{cgi} >> to be a CGI object which will be passed to
C<< Jifty->handler->handle_request >>.

=cut

sub play_request {
    my $self     = shift;
    my $request  = shift;
    my $filename = shift;

    %ENV = %{ $request->{ENV} };

    # this doesn't use "select $newhandle" because a few places in Jifty use
    # print STDOUT
    local *STDOUT;

    Jifty->log->info("Logging request's output to $filename.");

    open *STDOUT, '>', $filename
        or die "Unable to open $filename for writing: $!";

    Jifty->handler->handle_request(cgi => $request->{cgi});

    close *STDOUT;
}

=head2 play_requests NUMBER, REQUESTs

Plays through a list of requests, sleeping between each. Each request should be
a hashref with fields C<time> (a possibly fractional number of seconds,
representing the time of the request, relative to when the server started);
C<ENV> (used to set C<%ENV>); and C<cgi> (passed to
Jifty->handler->handle_request).

The NUMBER is used in logfile naming so different sets of requests don't
overwrite the same file.

=cut

sub play_requests {
    my $self    = shift;
    my $set_num = shift;

    my $current_time = 0;
    my $req_num = 0;

    for my $request (@_) {
        ++$req_num;

        $request->{time} -= $current_time;
        $request->{time} = $self->{max}
            if defined($self->{max}) && $request->{time} > $self->{max};

        Jifty->log->info("Next request in $request->{time} seconds.");
        sleep $request->{time};
        $current_time += $request->{time};

        my $filename = sprintf '%s/%d/%d-%d',
                        $path,
                        $start,
                        $set_num,
                        $req_num;

        $request->{cgi} = thaw($request->{cgi});

        $self->play_request($request, $filename);
    }
}

=head2 filename

This is used as a hack to get L<App::CLI> to retrieve our POD correctly.

Inner packages are not given in C<%INC>. If anyone finds a way around this,
please let us know.

=cut

sub filename { __FILE__ }

=head1 SEE ALSO

L<Jifty::Plugin::Recorder>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Best Practical Solutions

This is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;

