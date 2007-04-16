use strict;
use warnings;

package TestApp::Plugin::PasswordAuth::Model::User;
use Jifty::DBI::Schema;

# Mixins

use TestApp::Plugin::PasswordAuth::Record schema {
   column 'mygroup' =>
             valid_values are qw/admin moderator user/,
             default is 'user';

};

use TestApp::Plugin::FavoriteColor;
use TestApp::Plugin::FasterSwallow;
use Jifty::Plugin::User::Mixin::Model::User;
use Jifty::Plugin::Authentication::Password::Mixin::Model::User;

# Your model-specific methods go here.

1;

