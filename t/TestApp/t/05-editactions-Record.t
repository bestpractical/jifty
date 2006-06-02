#!/usr/bin/perl

use warnings;
use strict;

BEGIN {
chdir "t/TestApp";
$ENV{'JIFTY_CONFIG'} = 't/config-Record';
}
use lib '../../lib';

use Jifty::Test tests => 8;
use Jifty::Test::WWW::Mechanize;

# Make sure we can load the model
use_ok('TestApp::Model::User');

# Grab a system use
my $system_user = TestApp::CurrentUser->superuser;
ok($system_user, "Found a system user");

# Create a user
my $o = TestApp::Model::User->new(current_user => $system_user);
my ($id) = $o->create( name => 'edituser', email => 'someone@domain.com' );
ok($id, "User create returned success");

my $server  = Jifty::Test->make_server;

isa_ok($server, 'Jifty::Server');

my $URL     = $server->started_ok;
my $mech    = Jifty::Test::WWW::Mechanize->new();

# Test action to update
$mech->get_ok("$URL/editform?J:A-updateuser=TestApp::Action::UpdateUser&J:A:F:F:F-id-updateuser=1&J:A:F-name-updateuser=edituser&J:A:F-email-updateuser=newemail", "Form submitted");
undef $o;
$o = TestApp::Model::User->new(current_user => $system_user);
$o->load($id);
ok($id, "Load returned success");

is($o->email, 'newemail', "Email was updated by form");

1;

