use strict;
use warnings;

package TestApp::Plugin::AppPluginHasModels::Model::Texture;
use base qw/ TestApp::Plugin::AppPluginHasModels::Plugin::MyAppPlugin::Model::Texture /;

use Jifty::DBI::Schema;
use TestApp::Plugin::AppPluginHasModels::Record schema {
    # yeah, i know this is a lame schema...
    column exemplar =>
        references TestApp::Plugin::AppPluginHasModels::Model::Wallpaper;     
};

1;
