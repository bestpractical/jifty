#!/usr/bin/env perl
use warnings;
use strict;
use Jifty::Test::Dist tests => 4;
use Jifty::Test::WWW::Mechanize;

my $server = Jifty::Test->make_server;

isa_ok($server, 'Jifty::Server');

my $URL  = $server->started_ok;
my $mech = Jifty::Test::WWW::Mechanize->new();

$mech->get_ok("$URL", "Got the doc root");
$mech->content_like(qr/This installer will help you configure TestApp-Plugin-SetupWizard/, "setup wizard");

