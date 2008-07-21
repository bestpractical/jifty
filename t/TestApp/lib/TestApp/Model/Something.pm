use strict;
use warnings;

package TestApp::Model::Something;
use base qw/ TestApp::Record /;

use Jifty::DBI::Schema;
use Jifty::Record schema {
    column 'test3' => 
        type is 'text',
        ;
};

1
