#!/usr/bin/env perl
package Jifty::Plugin::Recorder::Command::Playback;

# this is just a shill to get Jifty::Script::Playback
# note that you'll need a patch to App::CLI to allow arbitrary
# files to define new commands

# you'll also need some kind of hack in Jifty::Script to use this file.
# still working on it!

package Jifty::Script::Playback;
use strict;
use warnings;

use base qw/App::CLI::Command/;
use Time::HiRes 'sleep';

sub options {
    (
     'max=s'    => 'max',
     'quiet'    => 'quiet',
     'dbiprof'  => 'dbiprof',
    )
}

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

sub play_request {
    my $self = shift;
    my $request = shift;

    # XXX: the output should go to a file for testability, and to suppress
    # the "print on closed filehandle" warnings
    close STDOUT;

    %ENV = %{ $request->{ENV} };
    Jifty->handler->handle_request(cgi => $request->{cgi});
}

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

1;

