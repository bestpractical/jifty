#!/usr/bin/env perl
use warnings;
use strict;

use Jifty::Test::Dist tests => 9;
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

get_ok("/woot");
$mech->content_contains("woot");

get_ok("/on_not_exist_show");
$mech->content_contains("woot");

get_nok("/something_that_really_not_exists");
$mech->warnings_like(qr/404/);
