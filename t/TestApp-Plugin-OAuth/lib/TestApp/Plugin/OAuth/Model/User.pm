use strict;
use warnings;

package TestApp::Plugin::OAuth::Model::User;
use Jifty::DBI::Schema;

use TestApp::Plugin::OAuth::Record schema {
    column 'tasty' =>
        type is 'boolean',
        default is 'f';

};

use Jifty::Plugin::User::Mixin::Model::User;
use Jifty::Plugin::Authentication::Password::Mixin::Model::User;

1;

