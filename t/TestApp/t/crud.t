#!/usr/bin/env perl
use warnings;
use strict;

use Jifty::Test::Dist tests => 3;
use Jifty::Test::WWW::Mechanize;

my $server = Jifty::Test->make_server;
isa_ok($server, 'Jifty::TestServer');

my $url = $server->started_ok;

my $mech = Jifty::Test::WWW::Mechanize->new;

$mech->get_ok("$url/crud/User");

# TODO FIXME XXX Surely more tests are needed... and don't call me Shirley.
