package TestApp::Plugin::OAuth::Model::User;
use base qw/Jifty::Record/;

use Jifty::DBI::Schema;
use Jifty::Record schema {
    column 'tasty' =>
        type is 'boolean';
};

use Jifty::Plugin::User::Mixin::Model::User;
use Jifty::Plugin::Authentication::Password::Mixin::Model::User;

1;

