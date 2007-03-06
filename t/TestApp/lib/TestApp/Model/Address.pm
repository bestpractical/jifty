use strict;
use warnings;

package TestApp::Model::Address;
use Jifty::DBI::Schema;

use constant CLASS_UUID => '0C51A3B2-CC25-11DB-AC90-0B3329635B38';

use TestApp::Record schema {
    column person =>
        refers_to TestApp::Model::User;
    column name =>
        type is 'text',
        label is 'Name';
    column street =>
        type is 'text',
        label is 'Street';
};

# Your model-specific methods go here.

1;

