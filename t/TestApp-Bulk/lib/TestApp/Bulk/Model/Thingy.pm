use strict;
use warnings;

package TestApp::Bulk::Model::Thingy;
use Jifty::DBI::Schema;

use TestApp::Bulk::Record schema {

  column value => type is 'text',  is mandatory;
  column user_id => type is 'int';

};

use Jifty::RightsFrom column => 'user';

1;

