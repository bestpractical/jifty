use strict;
use warnings;
use Jifty::Test::Dist tests => 10, actual_server => 1;
use Jifty::Test::WWW::Selenium;
use utf8;

my $server  = Jifty::Test->make_server;
my $sel = Jifty::Test::WWW::Selenium->rc_ok( $server );
my $URL = $server->started_ok;
diag $URL;

$sel->open_ok("/p/history/one");
$sel->wait_for_text_present_ok("This Is Page One");

$sel->open_ok("/p/history/two");
$sel->wait_for_text_present_ok("This Is Page Two");

$sel->open_ok("/p/history/three");
$sel->wait_for_text_present_ok("This Is Page Three");

$sel->go_back();
$sel->wait_for_text_present_ok("This Is Page Two");

$sel->go_back();
$sel->wait_for_text_present_ok("This Is Page One");

