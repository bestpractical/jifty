package Jifty::Plugin::OpenID::Mixin::Model::User;
use strict;
use warnings;
use Jifty::DBI::Schema;
use base 'Jifty::DBI::Record::Plugin';


use Jifty::Plugin::OpenID::Record schema {

column openid =>
  type is 'text',
  label is 'OpenID',
  hints is q{You can use your OpenID to log in quickly and easily.},
  is distinct,
  is immutable;

};

sub has_alternative_auth { 1 }

1;
