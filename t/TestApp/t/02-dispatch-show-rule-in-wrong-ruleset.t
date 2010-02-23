#!/usr/bin/env perl
use warnings;
use strict;

use Jifty::Test::Dist tests => 11;
use Jifty::Test::WWW::Mechanize;

my $server  = Jifty::Test->make_server;

isa_ok($server, 'Jifty::TestServer');

my $URL     = $server->started_ok;
my $mech    = Jifty::Test::WWW::Mechanize->new();

$mech->get("$URL/before_stage_show");
$mech->content_lacks("This is content");
is( $mech->status , '404');
$mech->warnings_like([qr/can't call a 'show' rule in a 'before' or 'after' block/, qr/404/]);

$mech->get("$URL/on_stage_show");
$mech->content_contains("his is content");

$mech->get("$URL/after_stage_show");
$mech->content_lacks("This is content");
is( $mech->status , '404');
$mech->warnings_like([qr/404/, qr/can't call a 'show' rule in a 'before' or 'after' block/]);

1;
