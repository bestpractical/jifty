#!/usr/bin/env perl
use warnings;
use strict;

BEGIN { $ENV{HTTPS} = 1; }

use Jifty::Test::Dist tests => 6;
use Jifty::Test::WWW::Mechanize;

my $server  = Jifty::Test->make_server;

isa_ok($server, 'Jifty::Server');

my $URL     = $server->started_ok;
my $mech    = Jifty::Test::WWW::Mechanize->new();
$URL =~ s/http:/https:/;

$mech->get_ok("$URL/dispatch/protocol", "Got /dispatch/protocol");
$mech->content_contains("HTTPS");
$mech->content_lacks("NOT");
$mech->content_contains("normal");


