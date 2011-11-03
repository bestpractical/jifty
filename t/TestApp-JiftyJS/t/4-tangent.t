# Test tangent / return

use strict;
use warnings;
use Jifty::Test::Dist tests => 17, actual_server => 1;
use Jifty::Test::WWW::Selenium;
use utf8;

my $server = Jifty::Test->make_server;
my $sel    = Jifty::Test::WWW::Selenium->rc_ok($server);
my $URL    = $server->started_ok;

$sel->open("/");
$sel->set_speed(1000);
$sel->pause();

{
    # /tangent/page1 -- tangent --> /tangent/returner -- return --> /tangent/page1

    $sel->open_ok("/tangent/page1");
    $sel->do_command_ok("clickAndWait", "to-returner");
    like $sel->get_location, qr{/tangent/returner}, "URL looks like /tangent/returner";
    $sel->do_command_ok("clickAndWait", "returner");
    like $sel->get_location, qr{/tangent/page1}, "URL looks like /tangent/page1";
}

{
    # /tangent/page2 -- tangent --> /tangent/returner -- return --> /tangent/page2

    $sel->open_ok("/tangent/page2");
    $sel->do_command_ok("clickAndWait", "to-returner");
    like $sel->get_location, qr{/tangent/returner}, "URL looks like /tangent/returner";
    $sel->do_command_ok("clickAndWait", "returner");
    like $sel->get_location, qr{/tangent/page2}, "URL looks like /tangent/page2j";
}

{
    # /tangent/page3 -- hyperlink --> /tangent/returner -- return --> /

    $sel->open_ok("/tangent/page3");
    $sel->do_command_ok("clickAndWait", "to-returner");
    like $sel->get_location, qr{/tangent/returner}, "URL looks like /tangent/returner";
    $sel->do_command_ok("clickAndWait", "returner");
    like $sel->get_location, qr{/}, "URL looks like /";
}

$sel->stop;
