# Test Action

use strict;
use warnings;
use lib 't/lib';
use Jifty::SubTest;
use Jifty::Test tests => 10;
use Jifty::Test::WWW::Selenium;
use utf8;

my $server = Jifty::Test->make_server;
my $sel    = Jifty::Test::WWW::Selenium->rc_ok($server);
my $URL    = $server->started_ok;

{
    # Test "Play" action's parameter.

    $sel->open_ok("/act/play");

    my $tags = '//input[contains(@class, "argument-tags")]';
    my $mood = '//input[contains(@class, "argument-mood")]';

    # Tag is ajax canonicalized to lowercase.

    $sel->set_speed(1000);
    $sel->click_ok($tags);
    $sel->type_ok($tags, "FOO");
    $sel->fire_event($tags, "blur");

    my $tag_value = $sel->get_value($tags);
    is $tag_value, 'foo', "Tags are canonicalized to lower-case";

    $sel->type_ok($mood, "FOO");
    $sel->fire_event($tags, "blur");
    is($sel->get_text('//span[contains(@class, "error text argument-mood")]'),
       "That doesn't look like a correct value",
       "mood validation error");

    $sel->type_ok($mood, "angry");
    $sel->fire_event($tags, "blur");
    is($sel->get_text('//span[contains(@class, "error text argument-mood")]'),
       "",
       "mood validation ok");

}

$sel->stop;
