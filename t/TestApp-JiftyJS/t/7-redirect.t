# This test is for testing Jifty.update() javascript function.

use strict;
use warnings;
use Jifty::Test::Dist actual_server => 1;
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
    /act/play2

type
    xpath=//input[@type='text']
    Not A Job Offer

click
    xpath=//input[@type='submit']

wait_for_text_present
    Redirected!

