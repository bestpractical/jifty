#!/usr/bin/env perl

use warnings;
use strict;

=head1 DESCRIPTION

Run tests with a fresh new Jifty.

=cut

use lib 't/lib';
use Jifty::SubTest;

use TestApp::DatabaseBackedModels::Test tests => 27;

ok(1, "Loaded the test script");

can_ok('TestApp::DatabaseBackedModels::Model::Widget', 'new');

my $u = Jifty::CurrentUser->new(_bootstrap => 1);
my $object = TestApp::DatabaseBackedModels::Model::Widget->new(current_user => $u);
isa_ok($object, 'TestApp::DatabaseBackedModels::Model::Widget');
isa_ok($object, 'TestApp::DatabaseBackedModels::Record');
can_ok($object, 'id');
can_ok($object, 'create');
can_ok($object, 'name');
can_ok($object, 'set_name');
can_ok($object, 'warehouse');
can_ok($object, 'set_warehouse');

my $id = $object->create( name => 'Widget');
ok($id, "Created id ".$id);
is($id,$object->id);
my $object_clone = TestApp::DatabaseBackedModels::Model::Widget->new(current_user => $u);

$object_clone->load($id);
is($object_clone->name, 'Widget');

my $warehouse = TestApp::DatabaseBackedModels::Model::Warehouse->new(current_user => $u);
isa_ok($warehouse, 'TestApp::DatabaseBackedModels::Model::Warehouse');
isa_ok($warehouse, 'TestApp::DatabaseBackedModels::Record');
can_ok($warehouse, 'id');
can_ok($warehouse, 'location');
can_ok($warehouse, 'set_location');
can_ok($warehouse, 'widgets');

$warehouse->load_by_cols( location => 'Manhattan' );
ok($warehouse->id);
is($warehouse->location, 'Manhattan');

my $widgets = $warehouse->widgets;
isa_ok($widgets, 'TestApp::DatabaseBackedModels::Model::WidgetCollection');
my $widget = $widgets->next;
ok($widget->id);
is($widget->name, 'Weeble');
is($widget->inventory, 6);
is($widget->warehouse->id, $warehouse->id);

$widget = $widgets->next;
is($widget, undef);

1;

