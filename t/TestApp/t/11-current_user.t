#!/usr/bin/env perl
use warnings;
use strict;

=head1 DESCRIPTION

Basic tests for CurrentUser.

=cut

use Jifty::Test::Dist tests => 33;
use Jifty::Test::WWW::Mechanize;

use_ok('TestApp::Model::User');
use_ok('TestApp::CurrentUser');

# Get a system user
my $system_user = TestApp::CurrentUser->superuser;
ok($system_user, "Found a system user");

# Make it so that all users have full access
TestApp::Model::User->add_trigger( before_access => sub { 'allow' } );

# Create two users
my $o = TestApp::Model::User->new(current_user => $system_user);
$o->create( name => 'A User', email => 'auser@example.com', 
            password => 'secret', tasty => 0 );
ok($o->id, "New user has valid id set");
ok(!$o->tasty, "User is not tasty");
$o->create( name => 'Bob', email => 'bob@example.com', 
            password => 'secret2', tasty => 1 );
ok($o->id, "New user has valid id set");
ok($o->tasty, "User is tasty");
is($o->created_on->time_zone->name, 'floating', "User's created_on date is in the floating timezone");
is($o->current_time->time_zone->name, 'UTC', "Jifty::DateTime::now defaults to UTC (superuser has no user_object)");

my $now = $o->current_time->clone;
$now->set_current_user_timezone('America/Chicago');
is($now->time_zone->name, 'America/Chicago', "set_current_user_timezone defaults to the passed in timezone");
$now->set_current_user_timezone();
is($now->time_zone->name, 'UTC', "set_current_user_timezone defaults to UTC if no passed in timezone");

is($o->email, 'bob@example.com', 'email initially set correctly');
$o->set_email('bob+jifty@example.com');
is($o->email, 'bob+jifty@example.com', 'email updated correctly');

# Create a CurrentUser
my $bob = TestApp::CurrentUser->new( name => 'Bob' );
ok($bob->id, "CurrentUser has a valid id set");
is($bob->id, $o->id, "The ids match");
ok($bob->user_object->tasty, "The CurrentUser is tasty");
ok($bob->is_superuser, "CurrentUser is a superuser");

is($bob->user_object->email, 'bob+jifty@example.com', 'email from before');
$bob->user_object->set_email('bob+test@example.com');
is($bob->user_object->email, 'bob+test@example.com', 'email updated correctly');
is($bob->user_object->created_on->time_zone->name, 'floating', "User's created_on date is in the floating timezone");
is($bob->user_object->current_time->time_zone->name, 'America/Anchorage', "Jifty::DateTime::now correctly peers into current_user->user_object->time_zone");

$now = $bob->user_object->current_time->clone;
$now->set_time_zone('America/New_York');
is($now->time_zone->name, 'America/New_York', "setting up other tests");
$now->set_current_user_timezone();
is($now->time_zone->name, 'America/Anchorage', "set_current_user_timezone correctly gets the user's timezone");
$now->set_current_user_timezone('America/Chicago');
is($now->time_zone->name, 'America/Anchorage', "set_current_user_timezone uses the user's in timezone even if one is passed in");

my $dt = Jifty::DateTime->from_epoch(epoch => time);
is($now->time_zone->name, 'America/Anchorage', "from_epoch correctly gets the user's timezone");

my $server = Jifty::Test->make_server;
isa_ok($server, 'Jifty::TestServer');

my $URL = $server->started_ok;
my $mech = Jifty::Test::WWW::Mechanize->new();

$mech->get_ok("$URL/currentuser", "Got currentuser page");
$mech->content_contains("No current user set.", "Good, no current user yet");
$mech->get_ok("$URL/setuser/Bob", "Setting currentuser to Bob");
$mech->get_ok("$URL/currentuser", "Refetched currentuser page");
$mech->content_contains("Current user is Bob", "Now the current_user is set");
$mech->content_contains("The current user is a superuser", "... and the current_user is a superuser");
