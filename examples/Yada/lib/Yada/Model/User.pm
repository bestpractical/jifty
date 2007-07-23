package Yada::Model::User;
#use base 'Example::Todo::Record';
use Jifty::DBI::Schema;

use Yada::Record schema {};

use Jifty::Plugin::User::Mixin::Model::User;
use Jifty::Plugin::Authentication::Password::Mixin::Model::User;
use Jifty::Plugin::OpenID::Mixin::Model::User;

1;
