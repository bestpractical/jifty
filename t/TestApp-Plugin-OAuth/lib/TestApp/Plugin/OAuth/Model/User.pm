package TestApp::Plugin::OAuth::Model::User;
use base qw/Jifty::Record/;

use Jifty::DBI::Schema;
use Jifty::Record schema {
    column 'name' =>
        type is 'text',
        is mandatory;
    column 'email' =>
        type is 'text',
        is mandatory;
    column 'tasty' =>
        type is 'boolean';
};

1;

