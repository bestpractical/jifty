# This test is for testing Jifty.update() javascript function.

use strict;
use warnings;
use lib 't/lib';
use Jifty::SubTest;
use Jifty::Test tests => 12;
use Jifty::Test::WWW::Selenium;
use utf8;

{
    my $server = Jifty::Test->make_server;
    my $sel    = Jifty::Test::WWW::Selenium->rc_ok($server);
    my $URL    = $server->started_ok;

    $sel->open_ok("/1-jifty-update.html");
    $sel->wait_for_text_present_ok("Jifty.update() tests");

    $sel->click_ok("region1");
    $sel->wait_for_text_present_ok("Region One");

    $sel->click_ok("region2");
    $sel->wait_for_text_present_ok("Region Two");

    # Update the same region path with different argument
    $sel->click_ok("region3");
    $sel->wait_for_text_present_ok("Hello, John");

    $sel->click_ok("region4");
    $sel->wait_for_text_present_ok("Hello, Smith");

    $sel->stop;
}

