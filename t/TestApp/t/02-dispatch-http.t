#!/usr/bin/env perl
use warnings;
use strict;

# Just in case
BEGIN { delete $ENV{HTTPS}; }

use Jifty::Test::Dist tests => 5;
use Jifty::Test::WWW::Mechanize;

my $server  = Jifty::Test->make_server;

isa_ok($server, 'Jifty::TestServer');

my $URL     = $server->started_ok;
my $mech    = Jifty::Test::WWW::Mechanize->new();

$mech->get_ok("$URL/dispatch/protocol", "Got /dispatch/protocol");
$mech->content_contains("NOT HTTPS");
$mech->content_contains("normal");

