#!/usr/bin/env perl
use strict;
use warnings;

use lib 't/lib';
use Jifty::SubTest;

use Jifty::Test tests => 8;

use_ok('TestApp::Model::User');
use_ok('TestApp::Model::Address');

my $system_user = TestApp::CurrentUser->superuser;
ok($system_user, 'got a system user');

my $user = TestApp::Model::User->new( current_user => $system_user );
$user->create( name => $$, email => $$, password => $$ );
ok($user->id, 'created a user');
ok($user->__uuid, 'user has a UUID');
like($user->__uuid, qr{[A-F0-9]{8}-(?:[A-F0-9]{4}-){3}[A-F0-9]{12}}i, 
    'the UUID is in the correct format');

my $address = TestApp::Model::Address->new( current_user => $system_user );
$address->create( person => $user->__uuid, name => $$, street => $$ );
ok($address->id, 'created an address');

is($address->person->id, $user->id, 'created address with correct user object');
