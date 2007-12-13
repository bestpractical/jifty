# This test is for testing Jifty.update() javascript function.

use strict;
use warnings;
use lib 't/lib';
use Jifty::SubTest;
use Jifty::Test tests => 12;
use Jifty::Test::WWW::Selenium;
use utf8;

my $sel    = Jifty::Test::WWW::Selenium->rc_ok($server);

$sel->open_ok("/1-jifty-update.html");

my $html = $sel->get_html_source;

like $html, qr{<h1>Jifty\.update\(\) tests</h1>}is;

$sel->click_ok("region1");
sleep 2;
$html = $sel->get_html_source;
like $html, qr{<p>Region One</p>}is;

$sel->click_ok("region2");
sleep 2;
$html = $sel->get_html_source;
like $html, qr{<p>Region Two</p>}is;


# Update the same region path with different argument
$sel->click_ok("region3");
sleep 2;
$html = $sel->get_html_source;
like $html, qr{<p>Hello, John</p>}is;

$sel->click_ok("region4");
sleep 2;
$html = $sel->get_html_source;
like $html, qr{<p>Hello, Smith</p>}is;

$sel->stop;

