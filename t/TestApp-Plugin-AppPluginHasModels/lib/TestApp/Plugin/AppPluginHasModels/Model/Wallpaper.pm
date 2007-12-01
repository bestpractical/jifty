use strict;
use warnings;

package TestApp::Plugin::AppPluginHasModels::Model::Wallpaper;
use Jifty::DBI::Schema;

use TestApp::Plugin::AppPluginHasModels::Record schema {
    column name =>
        type is 'text';

    column color =>
        references TestApp::Plugin::AppPluginHasModels::Model::Color;

    column texture =>
        references TestApp::Plugin::AppPluginHasModels::Model::Texture;
};

1;
