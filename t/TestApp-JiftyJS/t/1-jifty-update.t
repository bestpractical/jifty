# This test is for testing Jifty.update() javascript function.

use strict;
use warnings;
use Jifty::Test::Dist tests => 29, actual_server => 1;
use Jifty::Test::WWW::Selenium;
use utf8;

my $server = Jifty::Test->make_server;
my $sel    = Jifty::Test::WWW::Selenium->rc_ok($server);
my $URL    = $server->started_ok;

{
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

    $sel->click_ok("append-region");
    $sel->wait_for_text_present_ok("Hello, World");
    my $src = $sel->get_html_source();

    like $src, qr{<p>Hello, Smith</p>.+<p>Hello, World</p>}is;

    $sel->click_ok("prepend-region");
    $sel->pause();
    $sel->wait_for_text_present_ok("Hello, World");

    $src = $sel->get_html_source();

    like $src, qr{<p>Hello, World</p>.+<p>Hello, Smith</p>.+<p>Hello, World</p>}is;

    $sel->click_ok("delete-region");
    $sel->pause();

    ok(! $sel->is_element_present("region-content"), "'content' region is deleted." );

}



{
    # One click updates 3 regions, and triggers an alert.

    $sel->open_ok('/region/multiupdate');
    $sel->click_ok('update');
    $sel->get_alert_ok();

    $sel->wait_for_text_present_ok("Region One");
    $sel->wait_for_text_present_ok("Region Two");
    $sel->wait_for_text_present_ok("Hello, Pony");
}

{
    # Make sure there's 100 <p> element.
    # For any region update, using Jifty.udpate(), javascript code in there are always executed
    # after HTML is all done. This is to test how many <p> elements the javascript code
    # can get. And ithe number should be 100.
    $sel->open_ok('/p/zero');
    $sel->click_ok('xpath=//input');
    $sel->pause();
    my $msg = $sel->get_alert();
    is($msg, "100");
}

$sel->stop;
