#!/usr/bin/env perl

use warnings;
use strict;

BEGIN { $ENV{'JIFTY_CONFIG'} = 't/config-Cachable' }
use Jifty::Test::Dist tests => 7;
use Jifty::Test::WWW::Mechanize;

# Make sure we can load the model
use_ok('TestApp::Model::User');

# Grab a system use
my $system_user = TestApp::CurrentUser->superuser;
ok($system_user, "Found a system user");

# Create a user
my $o = TestApp::Model::User->new(current_user => $system_user);
my ($id) = $o->create( name => 'edituser', email => 'someone@example.com',
                       password => 'secret');
ok($id, "User create returned success");

my $server  = Jifty::Test->make_server;

isa_ok($server, 'Jifty::TestServer');

my $URL     = $server->started_ok;
my $mech    = Jifty::Test::WWW::Mechanize->new();

# Test action to update
$mech->post($URL.'/editform', {
    'J:A-updateuser' => 'TestApp::Action::UpdateUser',
    'J:A:F:F-id-updateuser' => 1,
    'J:A:F-name-updateuser' => 'edituser',
    'J:A:F-email-updateuser' => 'newemail@example.com',
    'J:A:F-tasty-updateuser' => '0'
});

undef $o;
$o = TestApp::Model::User->new(current_user => $system_user);
$o->flush_cache;
$o->load($id);
ok($id, "Load returned success");

is($o->email, 'newemail@example.com', "Email was updated by form");

1;

