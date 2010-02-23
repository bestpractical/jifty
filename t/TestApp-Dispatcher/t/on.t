#!/usr/bin/env perl
use warnings;
use strict;

use Jifty::Test::Dist tests => 25;
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

for(1..2) {
    get_ok("/on_array$_");
    $mech->content_contains("woot");
}

for(1..2) {
    get_ok("/on_array/$_");
    $mech->content_contains("woot");
}

get_ok("/on_re");
$mech->content_contains("woot");

for(1..2) {
    get_ok("/on/array/re$_");
    $mech->content_contains("woot");
}

get_ok("/on_run_run");
$mech->content_contains("woot");

get_ok("/on_arg");
$mech->content_contains("woot: x");

get_ok("/on_run_array");
$mech->content_contains("woot");

get_ok("/on_run_array_run");
$mech->content_contains("woot");

