package TestApp::Plugin::ActorMetadata::MyMixin;

use base 'Jifty::DBI::Record::Plugin';
use Jifty::DBI::Schema;


use Jifty::Plugin::User::Record schema {

column
  my_mixin_hello => type is 'varchar';

};

1;

