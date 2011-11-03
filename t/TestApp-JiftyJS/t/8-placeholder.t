# Test Action

use strict;
use warnings;
use Jifty::Test::Dist actual_server => 1;
use Jifty::Test::WWW::Selenium;
use utf8;

BEGIN {
    if (($ENV{'SELENIUM_RC_BROWSER'}||'') eq '*iexplore') {
        plan(skip_all => "Temporarily, until the 'Operation Abort' bug is solved.");
    }
    else {
        plan(tests => 6);
    }
}

my $server = Jifty::Test->make_server;
my $sel    = Jifty::Test::WWW::Selenium->rc_ok($server);
my $URL    = $server->started_ok;

$sel->open("/");

$sel->set_speed(1000);

{
    # Test placeholder
    $sel->open_ok("/act/play3");

    my $input = 'css=input[name="J:A:F-text-play2"]';

    $sel->is_element_present($input);
    my $text = $sel->get_value($input);

    is( $text, "foobar click me to enter text", "Initial content in the placeholder." );

    $sel->click_ok($input);
    $sel->fire_event($input, "focus");

    is( $sel->get_value($input), "", "Placeholder goes empty after clicking on it" );
}

$sel->stop;
