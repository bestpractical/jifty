use strict;
use warnings;

package TestApp::Plugin::ActorMetadata::Model::User;
use Jifty::DBI::Schema;

use TestApp::Plugin::ActorMetadata::Record schema {

};

use Jifty::Plugin::User::Mixin::Model::User;
use Jifty::Plugin::Authentication::Password::Mixin::Model::User;
# Your model-specific methods go here.

1;

