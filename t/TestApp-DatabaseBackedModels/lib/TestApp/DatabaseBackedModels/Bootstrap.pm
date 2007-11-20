package TestApp::DatabaseBackedModels::Bootstrap;
use warnings;
use strict;
use base 'Jifty::Bootstrap';

sub run { 
    my $user = TestApp::DatabaseBackedModels::CurrentUser->new( _bootstrap => 1);

    my $warehouse_model = Jifty::Model::ModelClass->new(current_user => $user);
    $warehouse_model->create( name => 'Warehouse' );

    my $location_col = Jifty::Model::ModelClassColumn->new(current_user => $user);
    $location_col->create( name => 'location', label_text => 'Location', storage_type => 'text', hints => 'This is the name of this location', model_class => $warehouse_model);

    my $widget_model = Jifty::Model::ModelClass->new(current_user => $user);
    $widget_model->create( name => 'Widget');

    my $name_col = Jifty::Model::ModelClassColumn->new(current_user => $user);
    $name_col->create( name => 'name', label_text => 'Name', storage_type => 'text', hints => 'This is the widget name', model_class => $widget_model);

    my $inventory_col = Jifty::Model::ModelClassColumn->new(current_user => $user);
    $inventory_col->create( name => 'inventory', label_text => 'Inventory', storage_type => 'int', hints => 'How many do we have on hand?', model_class => $widget_model);

    my $warehouse_col = Jifty::Model::ModelClassColumn->new(current_user => $user);
    $warehouse_col->create( name => 'warehouse', label_text => 'Warehouse', refers_to_class => 'TestApp::DatabaseBackedModels::Model::Warehouse', model_class => $widget_model );

    my $widgets_col = Jifty::Model::ModelClassColumn->new(current_user => $user);
    $widgets_col->create( name => 'widgets', refers_to_class => 'TestApp::DatabaseBackedModels::Model::WidgetCollection', refers_to_by => 'warehouse', model_class => $warehouse_model );

    my $warehouse = TestApp::DatabaseBackedModels::Model::Warehouse->new(current_user => $user);
    $warehouse->create(location => 'Manhattan');

    my $widget = TestApp::DatabaseBackedModels::Model::Widget->new(current_user => $user);
    $widget->create(name => 'Weeble', inventory => 6, warehouse => $warehouse);

};


1;
