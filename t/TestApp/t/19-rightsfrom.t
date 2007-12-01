#!/usr/bin/env perl
use warnings;
use strict;

=head1 DESCRIPTION

Test the RightsFrom mixin.

=cut

use lib 't/lib';
use Jifty::SubTest;

use Jifty::Test no_plan => 1;;

use_ok('TestApp::Model::User');
use_ok('TestApp::Model::Thingy');
use_ok('TestApp::Model::OtherThingy');
use_ok('TestApp::CurrentUser');

# Get a system user
my $system_user = TestApp::CurrentUser->superuser;
ok($system_user, "Found a system user");

# Create users
my $one = TestApp::Model::User->new(current_user => $system_user);
$one->create( name => 'A User', email => 'auser@example.com', 
            password => 'secret', tasty => 0 );
ok($one->id, "New user has valid id set");
is($one->name, "A User", "Has the right name");
my $two = TestApp::Model::User->new(current_user => $system_user);
$two->create( name => 'Bob', email => 'bob@example.com', 
            password => 'secret2', tasty => 0 );
ok($two->id, "New user has valid id set");

# Create a CurrentUser
my $one_user = TestApp::CurrentUser->new( id => $one->id );
ok($one_user->id, "Loaded the current user");
is($one_user->id, $one->id, "Has the right id");
is($one_user->user_object->id, $one->id, "User object is right");
is($one_user->user_object->name, $one->name, "Name is consistent");

my $two_by_one = TestApp::Model::User->new( current_user => $one_user );
$two_by_one->load( $two->id );
ok($two_by_one->id, "Has an id");
is($two_by_one->id, $two->id, "Has the right id");
ok(!$two_by_one->current_user_can("read"), "Can read the remote user");
ok(!$two_by_one->name, "Can't read their name");

# And a thingy and otherthingy, one from each user; thingy has
# rights_from 'user', otherthingy has rights from 'user_id';
for my $class (qw/TestApp::Model::Thingy TestApp::Model::OtherThingy/) {
    my $mine = $class->new(current_user => $system_user);
    $mine->create( user_id => $one->id, value => "Whee" );
    ok( $mine->id, "New object has a valid id");
    is( $mine->user_id, $one->id, "Has right user" );
    my $theirs = $class->new(current_user => $system_user);
    $theirs->create( user_id => $two->id, value => "Not whee" );
    ok( $theirs->id, "New object has a valid id");
    is( $theirs->user_id, $two->id, "Has right user" );

    my $access = $class->new( current_user => $one_user );
    $access->load( $mine->id );
    ok( $access->id, "Object has an id" );
    is( $access->id, $mine->id, "Has the right id" );
    ok( $access->current_user_can("read"), "I can read it");
    ok( $access->value, "Has a value" );
    is( $access->value, "Whee", "Can read the value" );
    isa_ok( $access->user, "TestApp::Model::User", "Has a user" );
    ok( $access->user_id, "Can read the user_id" );
    ok( $access->user->id, "Can read the user->id" );
    is( $access->user->id, $one->id, "Has the right user" );

    $access->load( $theirs->id );
    ok( $access->id, "Object has an id" );
    is( $access->id, $theirs->id, "Has the right id" );
    ok( !$access->current_user_can("read"), "I can't read it");
    ok( !$access->value, "Can't read the value" );
    isa_ok( $access->user, "TestApp::Model::User", "Has a user" );
    ok( !$access->user_id, "Can't read the user_id" );
    TODO:
    {
        local $TODO = "ACLs should apply to object refs, but can't";
        # Except the problem is that Jifty current_user_can's often
        # call their object refs, which would cause recursion.
        ok( !$access->user->id, "Can't read the user->id" );
    }
}
