#!/usr/bin/env perl

use warnings;
use strict;

=head1 DESCRIPTION

This is a template for your own tests. Copy it and modify it.

=cut

use lib 't/lib';
use Jifty::SubTest;

use Jifty::Test tests => 11;

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

my $id = $object->create( name => 'Widget');
ok($id, "Created id ".$id);
is($id,$object->id);
my $object_clone = TestApp::DatabaseBackedModels::Model::Widget->new(current_user => $u);

$object_clone->load($id);
is($object_clone->name, 'Widget');

1;

