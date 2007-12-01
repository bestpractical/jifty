#!/usr/bin/env perl
use warnings;
use strict;

=head1 DESCRIPTION

A basic test harness for the Color model.

=cut

use lib 't/lib';
use Jifty::SubTest;
use Jifty::Test tests => 16;

# Make sure we can load the model
use_ok('TestApp::Plugin::AppPluginHasModels::Model::Color');

# Grab a system user
my $system_user = TestApp::Plugin::AppPluginHasModels::CurrentUser->superuser;
ok($system_user, "Found a system user");

# Try testing a create
my $o = TestApp::Plugin::AppPluginHasModels::Model::Color->new(current_user => $system_user);
my ($id) = $o->create();
ok($id, "Color create returned success");
ok($o->id, "New Color has valid id set");
is($o->id, $id, "Create returned the right id");

# Does it use a prefixed table
is($o->table, 'myappplugin_colors', 'custom plugin table name');

# And another
$o->create();
ok($o->id, "Color create returned another value");
isnt($o->id, $id, "And it is different from the previous one");

# Searches in general
my $collection = TestApp::Plugin::AppPluginHasModels::Model::ColorCollection->new(current_user => $system_user);
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

# Needed for the action tests...
Jifty::Test->web;

# Make sure actions are available
isa_ok($collection->as_search_action, 'TestApp::Plugin::AppPluginHasModels::Action::SearchColor');
isa_ok($o->as_create_action, 'TestApp::Plugin::AppPluginHasModels::Action::CreateColor');
isa_ok($o->as_update_action, 'TestApp::Plugin::AppPluginHasModels::Action::UpdateColor');
isa_ok($o->as_delete_action, 'TestApp::Plugin::AppPluginHasModels::Action::DeleteColor');
