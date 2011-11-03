# Test simple continuation using the example in Jifty::Manual::Continuation

use strict;
use warnings;
use Jifty::Test::Dist tests => 24, actual_server => 1;
use Jifty::Test::WWW::Selenium;
use utf8;

my $server = Jifty::Test->make_server;
my $sel    = Jifty::Test::WWW::Selenium->rc_ok($server);
my $URL    = $server->started_ok;

{
    # /c/page1 -> /c/page2 -> /c/page1


    $sel->open_ok("/c/page1");
    $sel->wait_for_text_present_ok('first_number');

    my $field = '//input[contains(@class, "text")]';
    my $button = '//input[@type="submit"]';

    $sel->wait_for_element_present_ok($field);
    $sel->click_ok($field);
    $sel->type_ok($field, "100");

    $sel->do_command_ok("clickAndWait", $button);

    my $loc = $sel->get_location;
    like $loc, qr{/c/page2}, "URL looks like /c/page2";;

    $sel->click_ok($field);
    $sel->type_ok($field, "50");
    $sel->do_command_ok("clickAndWait", $button);

    $loc = $sel->get_location;
    like $loc, qr{/c/page1}, "URL looks like /c/page1";

}


{
    # /c/page_another_one -> /c/page2 -> /c/page_another_one

    $sel->open_ok("/c/page_another_one");
    $sel->wait_for_text_present_ok('first_number');

    my $field = '//input[contains(@class, "text")]';
    my $button = '//input[@type="submit"]';

    $sel->wait_for_element_present_ok($field);
    $sel->click_ok($field);
    $sel->type_ok($field, "100");

    $sel->do_command_ok("clickAndWait", $button);

    my $loc = $sel->get_location;
    like $loc, qr{/c/page2}, "URL looks like /c/page2";

    $sel->click_ok($field);
    $sel->type_ok($field, "50");
    $sel->do_command_ok("clickAndWait", $button);

    $loc = $sel->get_location;
    like $loc, qr{/c/page_another_one}, "URL looks like /c/page_another_one";
}



$sel->stop;
