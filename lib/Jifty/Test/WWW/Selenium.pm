package Jifty::Test::WWW::Selenium;
use strict;
use warnings;

use base 'Test::WWW::Selenium';

=head1 NAME

Jifty::Test::WWW::Selenium - Subclass of L<Test::WWW::Selenium> with
extra Jifty integration

=head1 SYNOPSIS

  use Jifty::Test::WWW::Selenium;
  my $server  = Jifty::Test->make_server;
  my $sel = Jifty::Test::WWW::Selenium->rc_ok( $server, lang => 'en_US.UTF-8' );
  my $URL = $server->started_ok;

  $sel->open_ok('/');

=head1 DESCRIPTION

L<Jifty::Test::WWW::Selenium> creates a L<Test::WWW::Selenium> object
associated with your jifty application to test.  In addition, it
starts selenium remote control for you, unless C<SELENIUM_RC_SERVER>
is specified when the test is run.  You might also want to set
C<SELENIUM_RC_TEST_AGAINST> to your local IP address so
C<SELENIUM_RC_SERVER> can test against you.  C<SELENIUM_RC_BROWSER>
tells the rc server what browser to run the tests with. You may want
to set C<SELENIUM_CLASS> to a subclass of L<Test::WWW::Selenium> to
refactor methods common to your application.

=head2 rc_ok

When the selenium rc server is started by
L<Jifty::Test::WWW::Selenium>, the browser's language is default to
en_US, unless you pass C<lang> param to rc_ok.

=cut

sub rc_ok {
    my $class = shift;
    my $server = shift;
    my %args = @_;

    $class->_skip_rest("live test doesn't work on Win32 at the moment")
                if $^O eq 'MSWin32';

    $ENV{JIFTY_OPENID_WHITELIST_HOST} = $ENV{SELENIUM_RC_TEST_AGAINST} || 'localhost';

    if ( $args{selenium_rc} ||= $ENV{SELENIUM_RC_SERVER} ) {
        @args{'host','port'} = split /:/, $args{selenium_rc}, 2;
    }
    else {
        @args{'host','port'} = eval { $class->_start_src(%args) };
        if ($@) {
            $class->_skip_rest("No selenium: $@");
        }
    }

    $args{browser_url} ||= 'http://'.($ENV{SELENIUM_RC_TEST_AGAINST} || $args{test_server} || 'localhost').':'.$server->port;

    $args{browser} ||= $ENV{SELENIUM_RC_BROWSER} || $class->_get_default_browser;
    $args{selenium_class} ||= $ENV{SELENIUM_CLASS} || 'Test::WWW::Selenium';

    $SIG{CHLD} = \&_REAPER;

    my $try = 5;
    my $sel;
    while ($try--) {
        $sel = eval { $args{selenium_class}->new( %args, auto_stop => 0 ) };
        last if $sel;
        Test::More::diag "waiting for selenium rc...";
        sleep 3;
    }

    if (!$sel) {
        $class->_skip_rest("No selenium");
    }

    Test::More::isa_ok($sel, 'Test::WWW::Selenium');
    return $sel;
}

sub _REAPER {
    my $waitedpid = wait;
    # loathe sysV: it makes us not only reinstate
    # the handler, but place it after the wait
    $SIG{CHLD} = \&_REAPER;
}

sub _get_default_browser {
    my $class = shift;

    return '*firefox /usr/lib/mozilla-firefox/firefox';
}

my @cleanup;

sub _start_src {
    my ($self, %args) = @_;
    eval 'require Alien::SeleniumRC; 1'
        or die 'requires Alien::SeleniumRC to start selenium-rc.';

    my $pid = fork();
    die if $pid == -1;
    if ($pid) {
        push @cleanup, $pid;
        return ('localhost', 4444);
    }
    else {
        unless ($^O eq 'MSWin32') {
            require POSIX;
            POSIX::setsid();  # Win32 doesn't have this.
        }
        unless ($ENV{TEST_VERBOSE}) {
            close *STDERR;
            close *STDOUT;
        }
        $ENV{LANG} = $args{lang} || 'en_US.UTF-8';
        $ENV{PATH} = "$ENV{PATH}:/usr/lib/firefox:/usr/lib/mozilla-firefox";
        Test::More::diag "start selenium rc [$$]";
        local $SIG{CHLD} = \&_REAPER;
        local $SIG{TERM} = sub { exit 0 };
        Alien::SeleniumRC::start(@{ $args{args} || [] });
        Test::More::diag "selenium rc [$$] finished.";
        exit;
    }
}

END {
    kill(15, -$_) for @cleanup;
}

sub _skip_rest {
    my $self = shift;
    my $why  = shift;

    # Schwern: i want skip_rest
    my $Tester = Test::Builder->new;
    $Tester->skip($why);

    unless ($Tester->{No_Plan}) {
        for my $ct ($Tester->{Curr_Test} + 1 .. $Tester->{Expected_Tests}) {
            $Tester->skip($why); # skip rest of the test
        }
    }
    $Tester->done_testing();
    exit(0);
}

1;
