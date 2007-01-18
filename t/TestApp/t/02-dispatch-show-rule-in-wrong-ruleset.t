#!/usr/bin/env perl
use warnings;
use strict;

use lib 't/lib';
use Jifty::SubTest;
use Jifty::Test tests => 8;
use Jifty::Test::WWW::Mechanize;

my $server  = Jifty::Test->make_server;

isa_ok($server, 'Jifty::Server');

my $URL     = $server->started_ok;
my $mech    = Jifty::Test::WWW::Mechanize->new();

$mech->get("$URL/before_stage_show", "Got /before_stage_show");
$mech->content_lacks("This is content");
is( $mech->status , '404');

$mech->get_ok("$URL/on_stage_show", "Got /on_stage_show");
$mech->content_contains("his is content");

$mech->get("$URL/after_stage_show", "Got /after_stage_show");
$mech->content_lacks("This is content");
is( $mech->status , '404');

1;
