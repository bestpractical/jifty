use warnings;
use strict;

package Jifty::Script::Server;
use base qw/Jifty::Script/;

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



use File::Path ();

use constant PIDFILE => 'var/jifty-server.pid';

=head1 NAME

Jifty::Script::Server - A standalone webserver for your Jifty application

=head1 SYNOPSIS

    jifty server
    jifty server --port 6666
    jifty server --stop

=head1 OPTIONS

=over 8

=item --port

The port to run the server on. Overrides the port in the config file, if it is
set there. The default port is 8888.

=item --stop

Stops the server.

=item --sigready

=item --quiet

=item --dbiprof

=item B<--help>

Print a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=back

=cut

sub options {
    my $self = shift;
    return (
        $self->SUPER::options,
        'p|port=s'   => 'port',
        'stop'       => 'stop',
        'sigready=s' => 'sigready',
        'quiet'      => 'quiet',
        'dbiprof'    => 'dbiprof',
    )
}

=head1 DESCRIPTION

When you're getting started with Jifty, this is the server you
want. It's lightweight and easy to work with.

=head1 METHODS

=head2 run

C<run> takes no arguments, but starts up a Jifty server process for
you.

=cut

sub run {
    my $self = shift;
    $self->print_help;
    Jifty->new();

    if ($self->{stop}) {
        open my $fh, '<', PIDFILE;
        my $pid = <$fh>;
        kill 'TERM' => $pid;
        return;
    }

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

    $SIG{TERM} = sub { exit };
    open my $fh, '>', PIDFILE or die $!;
    print $fh $$;
    close $fh;

    Jifty->handle->dbh->{Profile} = '6/DBI::ProfileDumper'
        if $self->{dbiprof};

    $ENV{JIFTY_SERVER_SIGREADY} ||= $self->{sigready}
        if $self->{sigready};
    Log::Log4perl->get_logger($server_class)->less_logging(3)
        if $self->{quiet};
    $server_class->new(port => $self->{port})->run;
}

1;
