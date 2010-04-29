package TestApp::Plugin::REST::Model::User;
use base qw/TestApp::Plugin::REST::Record/;

use Jifty::DBI::Schema;

# Your column definitions go here.  See L<Jifty::DBI::Schema> for
# documentation about how to write column definitions.

use Jifty::Record schema {
column 'name' =>
  type is 'text',
  is mandatory;
column 'email' =>
  type is 'text',
  is mandatory;
column 'tasty' =>
  type is 'boolean',
  is immutable;

column group_id => refers_to TestApp::Plugin::REST::Model::Group,
  label is 'Group',
  serialized as { name => 'group' } ;

};


# Your model-specific methods go here.

1;

