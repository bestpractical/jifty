#!/usr/bin/env perl
use warnings;
use strict;

use Jifty::Test::Dist tests => 7;
use Jifty::Test::WWW::Mechanize;
use Test::Log4perl;

my $server  = Jifty::Test->make_server;

isa_ok($server, 'Jifty::Server');

my $URL     = $server->started_ok;
my $mech    = Jifty::Test::WWW::Mechanize->new();

{
#    my $log = Test::Log4perl->expect(['', warn => qr/You can't call a 'show' rule in a 'before' or 'after' block in the dispatcher/ ]);
$mech->get("$URL/before_stage_show");
$mech->content_lacks("This is content");
is( $mech->status , '404');
}
$mech->get("$URL/on_stage_show");
#diag $mech->content;
$mech->content_contains("his is content");

$mech->get("$URL/after_stage_show");
$mech->content_lacks("This is content");
is( $mech->status , '404');

1;
