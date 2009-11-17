package Jifty::TestServer;

use strict;
use warnings;
use File::Spec;
use Test::Builder;
use Test::Script::Run 'get_perl_cmd';

=head1 NAME

Jifty::TestServer - Starting and stopping jifty server for tests

=head1 DESCRIPTION

=head1 METHOD

=head2 started_ok

Like started_ok in C<Test::HTTP::Server::Simple>, start the server and
return the URL.

=cut

sub started_ok {
    my $self = shift;
    my $text = shift;
    $text = 'started server' unless defined $text;

    if ($^O eq 'MSWin32') {
        # dirty hack until Test::Builder->skip_rest comes true

        my $why = "live test doesn't work on Win32 at the moment";

        my $Tester = Test::Builder->new;
        $Tester->skip($why);

        unless ($Tester->{No_Plan}) {
            for (my $ct = $Tester->{Curr_Test};
                    $ct < $Tester->{Expected_Tests};
                    $ct++
            ) {
                $Tester->skip($why); # skip rest of the test
            }
        }
        exit(0);
    }

    if (my $pid = fork()) {
        # We are expecting a USR1 from the child Jifty::Server
        # after it's ready to listen.
        $SIG{USR1} = sub { };
        sleep 15;
        $self->{started} = 1;
        my $Tester = Test::Builder->new;
        $Tester->ok(1, $text);
        # XXX: pull from jifty::config maybe
        return "http://localhost:".$self->port;
    } else {
        Jifty->handle->dbh->{'InactiveDestroy'} = 1;
        Jifty->setup_database_connection;
    }

    require POSIX;
    if ( $^O !~ /MSWin32/ ) {
        POSIX::setsid()
            or die "Can't start a new session: $!";
    }

    my @extra;
    if (my $profile_file = $ENV{JIFTY_TESTSERVER_PROFILE}) {
        push @extra, '-d:DProf';
        $ENV{"PERL_DPROF_OUT_FILE_NAME"} = $profile_file;
    }
    if ($ENV{JIFTY_TESTSERVER_NAMED_ACCESSOR}) {
        push @extra, '-MClass::Accessor::Named';
    }
    if (my $coverage = $ENV{JIFTY_TESTSERVER_COVERAGE}) {
        push @extra, '-MDevel::Cover'.($coverage =~ m/,/ ? "=$coverage" : '');
    }

    exec(get_perl_cmd(), @extra, '-MJifty::Util', '-MJifty::Script',
         '-e', 'Jifty::Script->dispatch', 'server', '--quiet',
         '--sigready', 'USR1',
         $ENV{JIFTY_TESTSERVER_DBIPROF} ? ('--dbiprof') : (),
         );
}

sub DESTROY {
    return unless $_[0]->{started};
    exec(get_perl_cmd('jifty'), 'server', '--stop');
}

1;
