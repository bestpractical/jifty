#!/usr/bin/perl
use warnings;
use strict;

BEGIN {chdir "t/TestApp"}
use lib '../../lib';
use Jifty::Test tests => 16;
use Jifty::Test::WWW::Mechanize;

my $server  = Jifty::Test->make_server;

isa_ok($server, 'Jifty::Server');

my $URL     = $server->started_ok;
my $mech    = Jifty::Test::WWW::Mechanize->new();

$mech->get_ok("$URL/dispatch/basic");
$mech->content_contains("Basic test.");
$mech->content_contains("Count 0");

$mech->get_ok("$URL/dispatch/basic-show");
$mech->content_contains("Basic test with forced show.");
$mech->content_contains("Count 1");

$mech->get_ok("$URL/dispatch/show/");
$mech->content_contains("Basic test with forced show.");
$mech->content_contains("Count 2");
$mech->content_lacks("Count 3");

$mech->get_ok("$URL/dispatch/");
$mech->content_contains("Basic test.");
$mech->content_contains("Count 3");
$mech->content_lacks("Count 4");



