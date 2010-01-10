#!/usr/bin/env perl
use warnings;
use strict;

=head1 DESCRIPTION

Basic tests for CurrentUser.

=cut

use Jifty::Test::Dist tests => 14;
#use Jifty::Test::WWW::Mechanize;

use_ok('TestApp::Plugin::PasswordAuth::Model::User');
use_ok('TestApp::Plugin::PasswordAuth::CurrentUser');

# Get a system user
my $system_user = TestApp::Plugin::PasswordAuth::CurrentUser->superuser;
ok($system_user, "Found a system user");

# Create two users
my $o = TestApp::Plugin::PasswordAuth::Model::User->new(current_user => $system_user);
$o->create( name => 'A User', email => 'auser@example.com', swallow_type => 'african',
            password => 'secret' );
ok($o->id, "New user has valid id set");
is($o->mygroup, 'user', "User is not admin");
$o->create( name => 'Bob', email => 'bob@example.com', swallow_type => 'african', 
            password => 'secret2', mygroup => 'admin' );
ok($o->id, "New user has valid id set");
is($o->mygroup, 'admin', "User is admin");

# Create a CurrentUser
my $bob = TestApp::Plugin::PasswordAuth::CurrentUser->new( name => 'Bob' );
ok($bob->id, "CurrentUser has a valid id set");
is($bob->id, $o->id, "The ids match");
is($bob->user_object->name, 'Bob', "The CurrentUser is Bob");
is($bob->user_object->email, 'bob@example.com', 'The CurrentUser email is bob@example.com');
is($bob->user_object->swallow_type, 'african', "The CurrentUser swallow_type is african");
is($bob->user_object->mygroup, 'admin', "The CurrentUser group is admin");
ok($bob->is_superuser, "CurrentUser is a superuser");

#my $server = Jifty::Test->make_server;
#isa_ok($server, 'Jifty::TestServer');

#my $URL = $server->started_ok;
#my $mech = Jifty::Test::WWW::Mechanize->new();

#$mech->get_ok("$URL/currentuser", "Got currentuser page");
#$mech->content_contains("No current user set.", "Good, no current user yet");
#$mech->get_ok("$URL/setuser/Bob", "Setting currentuser to Bob");
#$mech->get_ok("$URL/currentuser", "Refetched currentuser page");
#$mech->content_contains("Current user is Bob", "Now the current_user is set");
#$mech->content_contains("The current user is a superuser", "... and the current_user is a superuser");
