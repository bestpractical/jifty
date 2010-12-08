package Jifty::TestServer;
use Any::Moose;

use strict;
use warnings;
use File::Spec;
use Test::Builder;
use Test::Script::Run 'get_perl_cmd';
use Plack::Loader;

has port => (is => "rw", isa => "Int");

=head1 NAME

Jifty::TestServer - Starting and stopping jifty server for tests

=head1 DESCRIPTION

=head1 METHOD

=head2 started_ok

Like started_ok in C<Test::HTTP::Server::Simple>, start the server and
return the URL.

=head2 BUILD

Sets up the server instance.

=cut

sub BUILD {
    my $self = shift;
    Jifty->config->framework('Web')->{'Port'} = $self->port if $self->port;
    $self->port( Jifty->config->framework('Web')->{'Port'} || 8888 );
}

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

    $self->{plack_server} = Plack::Loader->load
        ($ENV{JIFTY_TEST_SERVER},
         port => $self->port,
         server_ready => sub {
             kill 'USR1' => getppid();
         });
    $Jifty::SERVER = $self;

    my $pid = fork();
    die "failed to fork" unless defined $pid;

    if ($pid) {
        # We are expecting a USR1 from the child process after it's
        # ready to listen.
        my $handled;
        $SIG{USR1} = sub { $handled = 1};
        sleep 15;
        Test::More::diag "did not get expected USR1 for test server readiness"
            unless $handled;
        $self->{cleanup} = [sub { kill TERM => $pid }];
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

    $self->{plack_server}->run(Jifty->handler->psgi_app);
    exit;
}

=head2 DEMOLISH

Calls any cleanup handlers before exiting

=cut

sub DEMOLISH {
    $_->() for @{$_[0]->{cleanup}}
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
