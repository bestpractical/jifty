use warnings;
use strict;

package Jifty::Script::Server;
use base qw/App::CLI::Command/;

# XXX: if test::builder is not used, sometimes connection is not
# properly closed, causing the client to wait for the content for a
# 302 redirect, see t/06-signup.t, which timeouts after test 24.
# If we load this after we load the rest of Jifty, its die handler clobbers ours.
# HATE.  And even worse, Test::Builder clobbers our global SIG{__DIE__} handler.
# So we work around the work around. The real answer is to figure out how Test::Builder 
# makes our test server not hang and do just that
my $x;
BEGIN {$x = $SIG{__DIE__}; }
use Test::Builder ();
BEGIN { $SIG{__DIE__} = $x;}


use Jifty::Everything;
use Jifty::Server;
use File::Path ();

use constant PIDFILE => 'var/jifty-server.pid';

=head1 NAME

Jifty::Script::Server - A standalone webserver for your Jifty application

=head1 DESCRIPTION

When you're getting started with Jifty, this is the server you
want. It's lightweight and easy to work with.

=head1 API

=head2 options

The server takes only one option, C<--port>, the port to run the
server on.  This is overrides the port in the config file, if it is
set there.  The default port is 8888.

=cut

sub options {
    (
     'p|port=s'   => 'port',
     'stop'       => 'stop',
     'sigready=s' => 'sigready',
     'quiet'      => 'quiet',
     'dbiprof'    => 'dbiprof',
    )
}

=head2 run

C<run> takes no arguments, but starts up a Jifty server process for
you.

=cut

sub run {
    my $self = shift;
    Jifty->new();

    if ($self->{stop}) {
        open my $fh, '<', PIDFILE;
        my $pid = <$fh>;
        kill 'TERM' => $pid;
        return;
    }

    # Purge stale mason cache data
    my $data_dir = Jifty->config->framework('Web')->{'DataDir'};
    if (-d $data_dir) {
        File::Path::rmtree(["$data_dir/cache", "$data_dir/obj"]);
    }

    $SIG{TERM} = sub { exit };
    open my $fh, '>', PIDFILE or die $!;
    print $fh $$;
    close $fh;

    Jifty->handle->dbh->{Profile} = '6/DBI::ProfileDumper'
        if $self->{dbiprof};

    $ENV{JIFTY_SERVER_SIGREADY} ||= $self->{sigready}
        if $self->{sigready};
    Log::Log4perl->get_logger("Jifty::Server")->less_logging(3)
        if $self->{quiet};

    Jifty::Server->new(port => $self->{port})->run;
}

1;
