use strict;
use warnings;

package TestApp::Plugin::AppPluginHasModels::Plugin::MyAppPlugin::Model::Texture;
use Jifty::DBI::Schema;

use TestApp::Plugin::AppPluginHasModels::Plugin::MyAppPlugin::Record schema {
    column name =>
        type is 'text';
};

1;
