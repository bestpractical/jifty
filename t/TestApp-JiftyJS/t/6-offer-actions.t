# This test is for testing Jifty.update() javascript function.

use strict;
use warnings;
use lib 't/lib';
use Jifty::SubTest;
use Jifty::Test;;
use Jifty::Test::WWW::Selenium;
use utf8;


$/ = undef;
my @commands = split /\n\n/, <DATA>;

plan tests => 2+@commands;

my $server = Jifty::Test->make_server;
my $sel    = Jifty::Test::WWW::Selenium->rc_ok($server);
my $URL    = $server->started_ok;

for (@commands) {
    my ($cmd, $arg1, $arg2) = (split(/\n\s*/, $_, 3), "", "");

    if ($cmd eq 'verify_text') {
        $arg2 =~ s/\s*$//;
        $arg2 =~ s/^\s*//;

        my $txt = $sel->get_text($arg1);
        is($txt, $arg2);
    }
    else {
        $cmd .= "_ok";
        $sel->$cmd($arg1, $arg2);
    }
}
$sel->stop;

__DATA__
open
    /__jifty/admin/model/Offer

type
    xpath=//div[contains(@class, "jifty_admin create item")]//input[contains(@type, "text")]
    Not A Job Offer

click
    xpath=//div[contains(@class,"submit_button")]/input

pause
    1000

wait_for_text_present
    Not A Job Offer

wait_for_element_present
    xpath=//span[contains(@class, "text argument-name value")]

wait_for_element_present
    xpath=//input[@type="checkbox"][@disabled="disabled"]

get_text
    xpath=//span[contains(@class, "text argument-name value")]
    Not A Job Offer
