#!/usr/bin/env perl
use warnings;
use strict;

use Jifty::Test::Dist tests => 39;
use Jifty::Test::WWW::Mechanize;

my $server  = Jifty::Test->make_server;

isa_ok($server, 'Jifty::TestServer');

my $URL = $server->started_ok;

my $mech = Jifty::Test::WWW::Mechanize->new;

$mech->get_ok("$URL/regions/list");

$mech->content_contains("Short $_")
  for (1 .. 5);

for my $i (1 .. 5) {
    ok($mech->find_link(text => "Short $i"), "Found link: Short $i");
    $mech->follow_link_ok(text => "Short $i");
    $mech->content_contains("Long $i");
}

$mech->content_contains("Long $_")
  for (1 .. 5);

ok($mech->find_link(text => "Long 1"), "Found link Long 1");
$mech->follow_link_ok(text => "Long 1");

$mech->content_contains("Short 1");
for my $i (2 .. 5) {
    $mech->content_contains("Long $i");
    $mech->content_lacks("Short $i");
}
