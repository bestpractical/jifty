package Jifty::Test::WWW::WebDriver;
use strict;
use warnings;

use base 'Test::WebDriver';

=head1 NAME

Jifty::Test::WebDriver - Subclass of L<Test::WebDriver> with
extra Jifty integration

=head1 SYNOPSIS

  use Jifty::Test::WWW::WebDriver;
  my $server  = Jifty::Test->make_server;
  my $sel = Jifty::Test::WWW::WebDriver->rc_ok( $server, lang => 'en_US.UTF-8' );
  my $URL = $server->started_ok;

  $sel->get_ok( $URL ));

=head1 DESCRIPTION

L<Jifty::Test::WWW::WebDriver> creates a L<Test::WebDriver> object
associated with your jifty application to test.  In addition, it
starts Selenium server for you, unless it finds a server already running.

You can specify where to look for the Selenium server using environment
variables: C<$TWD_HOST>, C<$TWD_PORT>, C<$TWD_BROWSER>.  See
L<Test::WebDriver> for all the options, and see L<Selenium::Remote::Driver>
for their meanings.

You may want to set C<TEST_CLASS> to a subclass of L<Test::WebDriver> to
refactor methods common to your application.

=head2 rc_ok

=cut

sub rc_ok {
    my $class = shift;
    my $server = shift;
    my %args = @_;

    $class->_skip_rest("live test doesn't work on Win32 at the moment")
                if $^O eq 'MSWin32';

    $ENV{JIFTY_OPENID_WHITELIST_HOST} = $ENV{SELENIUM_RC_TEST_AGAINST} || 'localhost';

    my ($host, $port) = $class->server_is_running;
    unless ($host and $port) {
        $class->_skip_rest("No selenium server was found.");
    }

    $args{browser_url} ||= 'http://'.($ENV{SELENIUM_RC_TEST_AGAINST} || $args{test_server} || 'localhost').':'.$server->port;

    $args{browser_name} ||= $ENV{TWD_BROWSER};
    $args{test_class} ||= 'Test::WebDriver';

    # This module does not yet launch selenium instances in the background, as
    # Selenium is not packaged in a way we can count on - eg: there is no
    # Alien package yet.
    my $sel = eval { $args{test_class}->new( %args, auto_close => 1 ) };
    if ($@) {
        $class->_skip_rest("Died trying to create a $args{test_class} object: $@");
    }
    if (!$sel) {
        $class->_skip_rest("No selenium server was found.");
    }

    $sel->{browser_url} = $args{browser_url};
    return $sel;
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
