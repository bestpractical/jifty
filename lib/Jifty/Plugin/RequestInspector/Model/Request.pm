use strict;
use warnings;

package Jifty::Plugin::RequestInspector::Model::Request;

use base qw( Jifty::Record );

use Jifty::DBI::Schema;
use Jifty::Record schema {

column data => type is 'blob',
  filters are 'Jifty::DBI::Filter::Storable';

};

sub since { '0.0.2' }

1;

