use strict;
use warnings;

package TestApp::Plugin::News::Model::News;
use Jifty::DBI::Schema;

# Mixins

use TestApp::Plugin::News::Record schema {

};

use  Jifty::Plugin::SiteNews::Mixin::Model::News;

1;

