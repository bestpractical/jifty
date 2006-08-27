package TestApp::Model::User::Schema;
use Jifty::DBI::Schema;
use Scalar::Defer;

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
column 'password' =>
  type is 'text',
  render_as 'Password',
  is mandatory,
  default is '';
column 'created_on' =>
  type is 'datetime',
  is immutable,
  default is defer { DateTime->now },
  filters are 'Jifty::DBI::Filter::DateTime';


package TestApp::Model::User;
use base qw/TestApp::Record/;

# Your model-specific methods go here.
sub current_user_can {
    return 1;
}

1;

