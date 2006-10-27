#!/usr/bin/perl -w

use Jifty::Test 'no_plan';
use Jifty::Test::WWW::Mechanize;

# Startup the ping server.
my $server = Jifty::Test->make_server;
isa_ok($server, 'Jifty::Server');

my $URL = $server->started_ok;
my $mech = Jifty::Test::WWW::Mechanize->new;

$mech->get_ok("$URL", "got the front page");
