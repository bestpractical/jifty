use strict;
use warnings;

package TestApp::Model::Author;
use Jifty::DBI::Schema;

use TestApp::Record schema {
    column name =>
        type is 'text';
};

# Your model-specific methods go here.

1;

