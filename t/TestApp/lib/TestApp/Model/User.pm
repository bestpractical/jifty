package TestApp::Model::User::Schema;
use Jifty::DBI::Schema;

# Your column definitions go here.  See L<Jifty::DBI::Schema> for
# documentation about how to write column definitions.

column 'name' =>
  type is 'text',
  is mandatory;
column 'email' =>
  type is 'text',
  is mandatory;
column 'tasty' =>
  type is 'boolean',
  is immutable;


package TestApp::Model::User;
use base qw/TestApp::Record/;

# Your model-specific methods go here.

1;

