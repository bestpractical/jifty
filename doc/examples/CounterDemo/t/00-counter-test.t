#!/usr/bin/env perl
use strict;
use warnings;

=head1 DESCRIPTION

Basic continuation counter test.

=cut

use Jifty::Test tests => 20;
use Jifty::Test::WWW::Mechanize;

my $server = Jifty::Test->make_server;

my $URL = $server->started_ok();

ok($URL, "Started the test server");

my $mech = Jifty::Test::WWW::Mechanize->new();

$mech->get_ok($URL, "Got the home page");

$mech->content_contains('The counter is: 0', "Counter starts at 0");
ok($mech->find_link(text => "++"), "Found the increment link");

$mech->follow_link_ok(text => "++");
$mech->content_contains('The counter is: 1', "Incremented the counter");

$mech->follow_link_ok(text => "++");
$mech->content_contains('The counter is: 2', "Incremented the counter");

$mech->follow_link_ok(text => "--");
$mech->content_contains('The counter is: 1', "Decremented the counter");

$mech->follow_link_ok(text => "--");
$mech->follow_link_ok(text => "--");
$mech->follow_link_ok(text => "--");
$mech->follow_link_ok(text => "--");

$mech->content_contains('The counter is: -3', "Decremented the counter 4 times");

$mech->back;
$mech->back;

$mech->content_contains('The counter is: -1', "Back at -1");

$mech->follow_link_ok(text => "--");

$mech->content_contains('The counter is: -2', "Going back then following links DTRT");

$mech->get($URL);
$mech->content_contains('The counter is: 0', "Loading the initial page again resets the counter");
