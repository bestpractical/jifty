use strict;
use warnings;

package TestApp::Plugin::Tag::Model::Node;
use Jifty::DBI::Schema;

use TestApp::Plugin::Tag::Record schema {
    column type =>
        type is 'varchar(32)',
        is mandatory,
        valid are qw(memo article news),
    ;
    column subject =>
        type is 'varchar(255)',
    ;
};

use Jifty::Plugin::Tag::Mixin::Model;

# Your model-specific methods go here.

1;
