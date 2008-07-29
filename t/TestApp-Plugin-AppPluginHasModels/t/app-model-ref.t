#!/usr/bin/env perl
use warnings;
use strict;

=head1 DESCRIPTION

A basic test harness for the Wallpaper model.

=cut

use Jifty::Test::Dist tests => 20;

# Make sure we can load the model
use_ok('TestApp::Plugin::AppPluginHasModels::Model::Wallpaper');

# Grab a system user
my $system_user = TestApp::Plugin::AppPluginHasModels::CurrentUser->superuser;
ok($system_user, "Found a system user");

# Try a color create
my $color = TestApp::Plugin::AppPluginHasModels::Model::Color->new(current_user => $system_user);
my ($color_id) = $color->create( name => 'Blue' );
ok($color_id, 'we have a color');

# Try a texture create
my $texture = TestApp::Plugin::AppPluginHasModels::Model::Texture->new(current_user => $system_user);
my ($texture_id) = $texture->create( name => 'Rough' );
ok($texture_id, 'we have a texture');

# Try testing a create
my $o = TestApp::Plugin::AppPluginHasModels::Model::Wallpaper->new(current_user => $system_user);
my ($id) = $o->create(
    name => 'Plaid',
    color => $color,
    texture => $texture,
);
ok($id, "Wallpaper create returned success");
ok($o->id, "New Wallpaper has valid id set");
is($o->id, $id, "Create returned the right id");
is($o->name, 'Plaid', 'name is Plaid');
is($o->color->name, 'Blue', 'color is Blue');
is($o->texture->name, 'Rough', 'texture is Rough');

# And another
$o->create();
ok($o->id, "Wallpaper create returned another value");
isnt($o->id, $id, "And it is different from the previous one");

# Searches in general
my $collection = TestApp::Plugin::AppPluginHasModels::Model::WallpaperCollection->new(current_user => $system_user);
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
isa_ok($collection->as_search_action, 'TestApp::Plugin::AppPluginHasModels::Action::SearchWallpaper');
isa_ok($o->as_create_action, 'TestApp::Plugin::AppPluginHasModels::Action::CreateWallpaper');
isa_ok($o->as_update_action, 'TestApp::Plugin::AppPluginHasModels::Action::UpdateWallpaper');
isa_ok($o->as_delete_action, 'TestApp::Plugin::AppPluginHasModels::Action::DeleteWallpaper');
