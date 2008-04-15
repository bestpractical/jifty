# This test is for testing Jifty.update() javascript function.

use strict;
use warnings;
use lib 't/lib';
use Jifty::SubTest;
use Jifty::Test;;
use Jifty::Test::WWW::Selenium;
use utf8;


$/ = undef;

my $data = <DATA>;
$data =~ s/^#.*$//gm;

my @commands = split /\n\n+/, $data;

plan tests => 2+@commands;

my $server = Jifty::Test->make_server;
my $sel    = Jifty::Test::WWW::Selenium->rc_ok($server);
my $URL    = $server->started_ok;

$sel->open("/");

for (@commands) {
    my ($cmd, $arg1, $arg2) = (split(/\n\s*/, $_, 3), "", "");

    $cmd =~ s{^ *}{}g;
    $cmd =~ s{ *$}{}g;
    $arg1 =~ s{\s*$}{};
    $arg2 =~ s{\s*$}{};

    $cmd .= "_ok";
    $sel->$cmd($arg1, $arg2);

}
$sel->stop;

__DATA__
open
    /__jifty/admin/model/Offer

type
    xpath=//div[contains(@class, "jifty_admin create item")]//input[@type="text"]
    Not A Job Offer

click
    xpath=//div[contains(@class,"submit_button")]//input

pause
    1000

wait_for_element_present
    xpath=//span[contains(@class, "value")][contains(@class, "argument-name")][contains(@class, "text")]

wait_for_text_present
    Not A Job Offer

wait_for_element_present
    xpath=//input[@type="checkbox"][contains(@class, "argument-is_job")]

get_text
    xpath=//span[contains(@class, "text")][contains(@class, "value")][contains(@class, "argument-name")]
    Not A Job Offer

####

open
    /__jifty/admin/model/Offer

type
    xpath=//div[contains(@class, "form_field")][contains(@class,"argument-name")]//input[@type="text"]
    Offer A Job

check
    xpath=//input[starts-with(@id, "J:A:F-is_job-create-")][@type="checkbox"]


# Click the "Create" button
click
    xpath=//div[@class="submit_button"]/input[@type="submit"][contains(@name,"J:ACTIONS=create-")]

pause
    1000

wait_for_element_present
    xpath=//input[@type="checkbox"][@checked]

get_text
    xpath=//span[contains(@class, "text")][contains(@class, "argument-name")][contains(@class, "value")]
    Offer A Job

