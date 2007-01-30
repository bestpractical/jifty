#!/usr/bin/env perl
use warnings;
use strict;

=head1 DESCRIPTION

A basic test harness for the User model.

=cut


use lib 't/lib';
use Jifty::SubTest;

use Jifty::Test tests => 12;
# Make sure we can load the model
use_ok('TestApp::Plugin::REST::Model::User');

# Grab a system use
my $system_user = TestApp::Plugin::REST::CurrentUser->superuser;
ok($system_user, "Found a system user");

# Try testing a create
my $o = TestApp::Plugin::REST::Model::User->new(current_user => $system_user);
my ($id) = $o->create( name => $$, email => $$ );
ok($id, "User create returned success");
ok($o->id, "New User has valid id set");
is($o->id, $id, "Create returned the right id");
is($o->name, $$, "Created object has the right name");

# And another
$o->create( name => $$, email => $$ );
ok($o->id, "User create returned another value");
isnt($o->id, $id, "And it is different from the previous one");

# Searches in general
my $collection =  TestApp::Plugin::REST::Model::UserCollection->new(current_user => $system_user);
$collection->unlimit;
is($collection->count, 2, "Finds two records");

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

