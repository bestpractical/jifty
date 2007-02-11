#!/usr/bin/env perl

use warnings;
use strict;

=head1 DESCRIPTION

This is a template for your own tests. Copy it and modify it.

=cut

use lib 't/lib';
use Jifty::SubTest;

use Jifty::Test tests => 23;

ok(1, "Loaded the test script");


my $u = Jifty::CurrentUser->new(_bootstrap => 1);
{
eval { my $model = TestApp::DatabaseBackedModels::Model::Object->new(current_user => $u); };
my $result = $@;
ok($result, "Failed to instantiate an 'object' model before running our tests");
}
my $model = Jifty::Model::ModelClass->new(current_user => $u);
$model->create(name => 'Object', description =>'You know. like widgets');
ok($model->id);

my $col = Jifty::Model::ModelClassColumn->new(current_user => $u);
$col->create(name => 'name', 
            model_class => $model,
            storage_type => 'text',
            label_text => 'Object name',
            hints => q{What's it called, yo?});

ok($col->id);
my $col2 = Jifty::Model::ModelClassColumn->new(current_user => $u);
$col2->create(name => 'inventory', 
            model_class => $model,
            storage_type => 'int',
            label_text => 'Volume on hand',
            hints => q{How many you gots?});

ok($col2->id, "Got column ".$col2->id);

my $col3 = Jifty::Model::ModelClassColumn->new(current_user => $u);
$col3->create(name => 'password', 
            model_class => $model,
            storage_type => 'text',
            render_as => 'Password',
            readable => 0,
            writable =>1
            );

ok($col3->id, "Got column ".$col2->id);


{
my $object = TestApp::DatabaseBackedModels::Model::Object->new(current_user => $u);
isa_ok($object, 'TestApp::DatabaseBackedModels::Model::Object');
can_ok($object, 'id');
can_ok($object, 'create');
can_ok($object, 'name');
can_ok($object, 'set_name');
can_ok($object, 'inventory');
can_ok($object, 'password');
can_ok($object, 'set_password');

my $id = $object->create( name => 'Widget', inventory => '30', password => 'secret');
ok($id, "Created id ".$id);
is($id,$object->id);
my $object_clone = TestApp::DatabaseBackedModels::Model::Object->new(current_user => $u);

$object_clone->load($id);
is($object_clone->name, 'Widget');
is($object_clone->inventory, '30');
is($object_clone->password,'');
is($object_clone->__value('password'), 'secret');
$object_clone->set_password('foo!');

is($object_clone->__value('password'), 'foo!');

$object_clone->set_inventory(40);
is($object_clone->inventory, 40);
$object_clone->set_name('Thingy');
is($object_clone->name, 'Thingy');


}



# upgrade tests
#
# test that our bootstrapped models exist
#
# add a column to a bootstrapped model class (widgets)
# can our widget objects now see the new column?
# does the widgets table have the new column?
# is the table's default correct?
# do live widget objects magically have the new default?
#
# remove a column
# do live objects lose that column?
# do freshly loaded objects lose that column
# do the column methods for the objects fail on the fly?



# create a new modelclass
# it instantiates the class
# it autocreates the table in the database

# add a column to the table
# it updates the table in the database
# it updates the model class

# delete the new modelclass
# it deletes the table in the database
# it deletes the model class from memory
# existing objects are ????

1;

