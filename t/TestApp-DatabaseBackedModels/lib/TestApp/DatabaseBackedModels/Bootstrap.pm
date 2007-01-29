package TestApp::DatabaseBackedModels::Bootstrap;
use warnings;
use strict;
use base 'Jifty::Bootstrap';
sub run { 

    my $user = TestApp::DatabaseBackedModels::CurrentUser->new( _bootstrap => 1);
    my $modelclass = Jifty::Model::ModelClass->new(current_user => $user);
    $modelclass->create( name => 'Widget');

    my $col = Jifty::Model::ModelClassColumn->new(current_user => $user);
    $col->create( name => 'name', label => 'Name', storage_type => 'text', hints => 'This is the widget name', model_class => $modelclass);
    #   my $col2 = Jifty::Model::ModelClassColumn->new(current_user => $user);
    #$col2->create( name => 'inventory', label => 'Inventory', storage_type => 'int', hints => 'How many do we have on hand?', model_class => $modelclass);

};


1;
