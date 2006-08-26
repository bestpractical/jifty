#!/usr/bin/env perl
use warnings;
use strict;

=head1 DESCRIPTION

Basic tests for CurrentUser.

=cut

BEGIN {
    #### XXX: I know this is foolish but right now Jifty on Win32 fails to 
    #### unlink used test databases and the following tests fail saying
    #### 'error creating a table... table already exists'. So, remove the
    #### remnant first. And we should do it before none of the Jifty is there.

    my $testdb = 't/TestApp/testapptest';
    if (-e $testdb) {
        unlink $testdb or die $!;
    }
}

use lib 't/lib';
use Jifty::SubTest;

use Jifty::Test tests => 19;
use Jifty::Test::WWW::Mechanize;

use_ok('TestApp::Model::User');
use_ok('TestApp::CurrentUser');

# Get a system user
my $system_user = TestApp::CurrentUser->superuser;
ok($system_user, "Found a system user");

# Create two users
my $o = TestApp::Model::User->new(current_user => $system_user);
$o->create( name => 'A User', email => 'auser@example.com', tasty => 0 );
ok($o->id, "New user has valid id set");
ok(!$o->tasty, "User is not tasty");
$o->create( name => 'Bob', email => 'bob@example.com', tasty => 1 );
ok($o->id, "New user has valid id set");
ok($o->tasty, "User is tasty");

# Create a CurrentUser
my $bob = TestApp::CurrentUser->new( name => 'Bob' );
ok($bob->id, "CurrentUser has a valid id set");
is($bob->id, $o->id, "The ids match");
ok($bob->user_object->tasty, "The CurrentUser is tasty");
ok($bob->is_superuser, "CurrentUser is a superuser");

my $server = Jifty::Test->make_server;
isa_ok($server, 'Jifty::Server');

my $URL = $server->started_ok;
my $mech = Jifty::Test::WWW::Mechanize->new();

$mech->get_ok("$URL/currentuser", "Got currentuser page");
$mech->content_contains("No current user set.", "Good, no current user yet");
$mech->get_ok("$URL/setuser/Bob", "Setting currentuser to Bob");
$mech->get_ok("$URL/currentuser", "Refetched currentuser page");
$mech->content_contains("Current user is Bob", "Now the current_user is set");
$mech->content_contains("The current user is a superuser", "... and the current_user is a superuser");
