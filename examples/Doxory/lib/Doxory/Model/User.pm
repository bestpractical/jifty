use strict;
use warnings;

package Doxory::Model::User;
use Jifty::DBI::Schema;

use Doxory::Record schema {

column name =>
    label is 'Username',
    hints is 'Other people see this when you ask questions.',
    is distinct, is mandatory;

column email =>
    label is 'Email',
    hints is 'We will not sell it to anybody. Honest.',
    default is '',
    is distinct, is immutable;

};

use Jifty::Plugin::User::Mixin::Model::User;
use Jifty::Plugin::Authentication::Password::Mixin::Model::User;

# Your model-specific methods go here.
1;

