use strict;
use warnings;

package TestApp::Plugin::PasswordAuth::Model::User;
use Jifty::DBI::Schema;

# Mixins

use TestApp::Plugin::PasswordAuth::Record schema {

};

use Jifty::Plugin::User::Model::User;
use Jifty::Plugin::Authentication::Password::Model::User;

# Your model-specific methods go here.

1;

