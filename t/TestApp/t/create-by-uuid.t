#!/usr/bin/env perl
use strict;
use warnings;

use lib 't/lib';
use Jifty::SubTest;

use Jifty::Test tests => 6;

use_ok('TestApp::Model::User');
use_ok('TestApp::Model::Address');

my $system_user = TestApp::CurrentUser->superuser;
ok($system_user, 'got a system user');

my $user = TestApp::Model::User->new( current_user => $system_user );
$user->create( name => $$, email => $$, password => $$ );
ok($user->id, 'created a user');

my $address = TestApp::Model::Address->new( current_user => $system_user );
$address->create( person => $user->__uuid, name => $$, street => $$ );
ok($address->id, 'created an address');

is($address->person->id, $user->id, 'created address with correct user object');
