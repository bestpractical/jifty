#!/usr/bin/perl -w

use warnings;
use strict;

BEGIN {chdir "t/TestApp"}
use lib '../../lib';
use Jifty::Test tests => 6;
use Jifty::Test::WWW::Mechanize;

my $server  = Jifty::Test->make_server;

isa_ok($server, 'Jifty::Server');

my $URL     = $server->started_ok;
my $mech    = Jifty::Test::WWW::Mechanize->new();

use_ok('TestApp::Model::User');

my $user = TestApp::Model::User->new();

my ($id, $msg) = $user->create( name => $$, email => $$.'@example.com');

ok($id, "Created a new user: ".$msg);
is ($id, $user->id);
is($user->name, $$);

1;
