#!/usr/bin/env perl
use warnings;
use strict;

use Jifty::Test::Dist tests => 32;
use Jifty::Test::WWW::Mechanize;

my $server = Jifty::Test->make_server;
ok($server, 'got a server');

isa_ok($server, 'Jifty::TestServer');

my $url     = $server->started_ok;
my $mech    = Jifty::Test::WWW::Mechanize->new();

sub get_ok($) {
    my $path = shift;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $mech->get_ok($url.$path, "got $path");
}

sub get_nok($) {
    my $path = shift;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $mech->get($url.$path);
    is $mech->status, 404, "no $path (404)";
}

for(qw!some another some/deep!) {
    get_ok("/under_any/$_");
    $mech->content_contains("woot");
}

for(qw!some another some/deep!) {
    get_ok("/under/some_any/$_");
    $mech->content_contains("woot");
}

for(qw!some another some/deep!) {
    get_ok("/under_re/$_");
    $mech->content_contains("woot: $_");
}

get_ok("/under_run_array_on/woot");
$mech->content_contains("woot");

get_ok("/under_run_on_re/woot");
$mech->content_contains("woot");

{
    get_ok("/under_run_on_exist_run/exist");
    $mech->content_contains("woot: exist");
    {
        local $TODO = "Nested under and on rules fail";
        get_nok("/under_run_on_exist_run/not_exist");
    }
}

diag('test caching of compiled regular expressions') if $ENV{TEST_VERBOSE};
{
    get_ok("/under_run_on_special/some_special");
    $mech->content_contains("woot: under");
    get_ok("/some_special");
    $mech->content_contains("woot: top");
}

