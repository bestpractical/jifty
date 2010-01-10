#!/usr/bin/env perl

use warnings;
use strict;

BEGIN { $ENV{'JIFTY_CONFIG'} = 't/config-Record' }
use Jifty::Test::Dist tests => 9;
use Jifty::Test::WWW::Mechanize;
# Make sure we can load the model
use_ok('TestApp::Model::User');

# Grab a system use
my $system_user = TestApp::CurrentUser->superuser;
ok($system_user, "Found a system user");

# Create a user
my $o = TestApp::Model::User->new(current_user => $system_user);
my ($id) = $o->create( name => 'edituser', email => 'someone@example.com',
                       password => 'secret', tasty => 1 );
ok($id, "User create returned success");
is($o->tasty, 1, "User is tasty");

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
$o->load($id);
ok($id, "Load returned success");


is($o->email, 'newemail@example.com', "Email was updated by form");
is($o->tasty, 1, "User is still tasty (was not updated since immutable)");
1;

