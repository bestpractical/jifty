#!/usr/bin/env perl
use lib 't/TestApp-Plugin-SetupWizard/lib';
use TestApp::Plugin::SetupWizard::Test tests => 4;

my $server = Jifty::Test->make_server;

isa_ok($server, 'Jifty::Server');

my $URL  = $server->started_ok;
my $mech = Jifty::Test::WWW::Mechanize->new();

$mech->get_ok("$URL", "Got the doc root");
$mech->content_like(qr/This installer will help you configure TestApp-Plugin-SetupWizard/, "setup wizard");

