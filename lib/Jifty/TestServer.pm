package Jifty::TestServer;

use strict;
use warnings;
use Cwd 'abs_path';
use Test::Builder;
my $Tester = Test::Builder->new;

my $INC = [map { abs_path($_) } @INC ];
my @perl = ($^X, map { "-I$_" } @$INC);

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

    if (my $pid = fork()) {
        # We are expecting a USR1 from the child Jifty::Server
        # after it's ready to listen.
        $SIG{USR1} = sub { };
        sleep 15;
        $self->{started} = 1;
        $Tester->ok(1, $text);
        # XXX: pull from jifty::config maybe
        return "http://localhost:".$self->port;
    }

    require POSIX;
    if ( $^O !~ /MSWin32/ ) {
        POSIX::setsid()
            or die "Can't start a new session: $!";
    }

    my @extra;
    if (my $profile_file = $ENV{JIFTY_TESTSERVER_PROFILE}) {
        push @extra, '-d:DProf', '-MClass::Accessor::Named';
        $ENV{"PERL_DPROF_OUT_FILE_NAME"} = $profile_file;
    }
    if (my $coverage = $ENV{JIFTY_TESTSERVER_COVERAGE}) {
        push @extra, '-MDevel::Cover'.($coverage =~ m/,/ ? "=$coverage" : '');
    }

    exec(@perl, @extra, '-MJifty::Util', '-MJifty::Script',
         '-e', 'Jifty::Script->dispatch', 'server', '--quiet',
         '--sigready', 'USR1',
         $ENV{JIFTY_TESTSERVER_DBIPROF} ? ('--dbiprof') : (),
         );
}

sub DESTROY {
    return unless $_[0]->{started};
    exec(@perl, 'bin/jifty', 'server', '--stop');
}

1;
