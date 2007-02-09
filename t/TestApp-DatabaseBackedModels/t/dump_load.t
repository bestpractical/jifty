#!/usr/bin/env perl

use warnings;
use strict;

=head1 DESCRIPTION

This is a template for your own tests. Copy it and modify it.

=cut

use lib 't/lib';
use Jifty::SubTest;

use Jifty::Test tests => 10;



ok(1, "Loaded the test script");
Jifty->new();
use_ok('Jifty::Script::Database');
can_ok('TestApp::DatabaseBackedModels::Model::Widget', 'new');

my $DATABASE = Jifty::Script::Database->new();

my $dumped_bootstrap = $DATABASE->_models_to_hash();

my @keys = sort keys %$dumped_bootstrap;

is_deeply(\@keys, [qw/Jifty::Model::Metadata 
                    Jifty::Model::ModelClass 
                    Jifty::Model::ModelClassColumn
                    TestApp::DatabaseBackedModels::Model::Widget
                    /]);

my $dumped_widgets = $dumped_bootstrap->{'TestApp::DatabaseBackedModels::Model::Widget'};
is (scalar keys %$dumped_widgets, 1);
my @values = values %$dumped_widgets;
my $widget = shift @values;
is ($widget->{'name'}, 'Weeble', "Dumped data is as expected");


my %new_widgets = ( 'TestApp::DatabaseBackedModels::Model::Widget' => { 
    2 => { name => 'Fleeble', inventory => 5 },
    3 => { name => 'Greeble', inventory => 0 },
}
);



$DATABASE->_load_data(\%new_widgets);
my $widgets = TestApp::DatabaseBackedModels::Model::WidgetCollection->new();
$widgets->unlimit();
is ($widgets->count,3, "We've loaded our two new widgets");

{
my %new_tables = (
    'Jifty::Model::ModelClass' => {
        'cb05ac8c-afa5-11db-b33d-6f303ef246eb' =>
            { name => 'Customer', description => 'People who pay us' },
        'cb05ae08-afa5-11db-b33e-bbf514ba3e02' =>
            { name => 'Vendor', description => 'People we avoid paying' }
    }
);
$DATABASE->_load_data(\%new_tables);
can_ok('TestApp::DatabaseBackedModels::Model::Customer', 'new');
can_ok('TestApp::DatabaseBackedModels::Model::Customer', 'create');
isa_ok(TestApp::DatabaseBackedModels::Model::Customer->new(), 'Jifty::DBI::Record');

my $obj = TestApp::DatabaseBackedModels::Model::Customer->create();
ok($obj->id, "Created a customer.");
}


{
my %new_tables = (
    'Jifty::Model::ModelClass' => {
        'cb05ac8c-afa5-11db-b33d-6f303ef246eb' =>
            { name => 'Customer', description => 'People who pay us' },
        'cb05ae08-afa5-11db-b33e-bbf514ba3e02' =>
            { name => 'Vendor', description => 'People we avoid paying' }
    },
    'Jifty::Model::ModelClassColumn' => {
            'cb05ac8c-afa5-11db-b33d-6f303ef246ef' => 
                { name => 'name', type => 'text', model_class => 'cb05ac8c-afa5-11db-b33d-6f303ef246eb', default_value => 'Cogswell Cogs' }
    } 
);
$DATABASE->_load_data(\%new_tables);
can_ok('TestApp::DatabaseBackedModels::Model::Customer', 'new');
can_ok('TestApp::DatabaseBackedModels::Model::Customer', 'create');
can_ok('TestApp::DatabaseBackedModels::Model::Customer', 'name');
can_ok('TestApp::DatabaseBackedModels::Model::Customer', 'set_name');
isa_ok(TestApp::DatabaseBackedModels::Model::Customer->new(), 'Jifty::DBI::Record');
my $customers = TestApp::DatabaseBackedModels::Model::CustomerCollection->new;
$customers->unlimit();
is($customers->count(),1);
is($customers->first->name, 'Cogswell Cogs');
can_ok('TestApp::DatabaseBackedModels::Model::Vendor', 'new');
can_ok('TestApp::DatabaseBackedModels::Model::Vendor', 'create');
ok(!can('TestApp::DatabaseBackedModels::Model::Vendor', 'name'));


}
