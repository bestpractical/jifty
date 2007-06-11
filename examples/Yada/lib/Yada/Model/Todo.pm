use strict;
use warnings;

package Yada::Model::Todo;
use Jifty::DBI::Schema;

use Yada::Record schema {

    column done => type is 'bool';
    column description => type is 'text';

};

# Your model-specific methods go here.

1;

