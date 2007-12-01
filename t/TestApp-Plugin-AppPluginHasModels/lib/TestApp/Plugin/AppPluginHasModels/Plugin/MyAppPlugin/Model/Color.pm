use strict;
use warnings;

package TestApp::Plugin::AppPluginHasModels::Plugin::MyAppPlugin::Model::Color;
use Jifty::DBI::Schema;

use TestApp::Plugin::AppPluginHasModels::Plugin::MyAppPlugin::Record schema {
    column name =>
        type is 'text';

    column contrasting_color =>
        type is 'text';
};

sub table { 'myappplugin_colors' }

1;
