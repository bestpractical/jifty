#!/usr/bin/env perl
use warnings;
use strict;

=head1 DESCRIPTION

A basic test harness for the User model.

=cut

use Jifty::Test::Dist tests => 26;
Jifty::Test->web; # initialize for use with the as_*_action tests
# Make sure we can load the model
use_ok('TestApp::Model::User');

# Grab a system use
my $system_user = TestApp::CurrentUser->superuser;
ok($system_user, "Found a system user");

# Try testing a create
my $o = TestApp::Model::User->new(current_user => $system_user);
my ($id) = $o->create( name => $$, email => $$, password => $$ );
ok($id, "User create returned success");
ok($o->id, "New User has valid id set");
is($o->id, $id, "Create returned the right id");
is($o->name, $$, "Created object has the right name");

is $o->my_data, undef, 'my_data is undef';
$o->set_my_data( { foo => 'bar' } );
is_deeply $o->my_data, { foo => 'bar' }, 'my_data filtered correctly';

# Test the as_foo_action methods
my $action = $o->as_create_action( moniker => 'test1' );
isa_ok($action, 'TestApp::Action::CreateUser');
is($action->moniker, 'test1', 'create action moniker is test1');
$action = $o->as_update_action( moniker => 'test2' );
isa_ok($action, 'TestApp::Action::UpdateUser');
is($action->record->id, $o->id, 'update action ID is correct');
is($action->moniker, 'test2', 'update action moniker is test2');
$action = $o->as_delete_action( moniker => 'test3' );
isa_ok($action, 'TestApp::Action::DeleteUser');
is($action->record->id, $o->id, 'delete action ID is correct');
is($action->moniker, 'test3', 'delete action moniker is test3');
$action = $o->as_search_action( moniker => 'test4' );
isa_ok($action, 'TestApp::Action::SearchUser');
is($action->moniker, 'test4', 'search action moniker is test4');

# And another
$o->create( name => $$, email => $$, password => $$ );
ok($o->id, "User create returned another value");
isnt($o->id, $id, "And it is different from the previous one");

# Searches in general
my $collection =  TestApp::Model::UserCollection->new(current_user => $system_user);
$collection->unlimit;
is($collection->count, 2, "Finds two records");

# Check the as_search_action method
$action = $collection->as_search_action( moniker => 'test5' );
isa_ok($action, 'TestApp::Action::SearchUser');
is($action->moniker, 'test5', 'search action moniker is test5');

# Searches in specific
$collection->limit(column => 'id', value => $o->id);
is($collection->count, 1, "Finds one record with specific id");

# Delete one of them
$o->delete;
$collection->redo_search;
is($collection->count, 0, "Deleted row is gone");

# And the other one is still there
$collection->unlimit;
is($collection->count, 1, "Still one left");

