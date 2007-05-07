use strict;
use warnings;

package Example::Todo::Model::Todo;
use Jifty::DBI::Schema;

use Example::Todo::Record schema {

    column done => type is 'bool';
    column description => type is 'text';

};

# Your model-specific methods go here.

1;

