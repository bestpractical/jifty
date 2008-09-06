use strict;
use warnings;

package TestApp::Model::Book;
use Jifty::DBI::Schema;

use TestApp::Record schema {
    column title =>
        type is 'text';
    column author =>
        refers_to TestApp::Model::AuthorCollection by 'name',
        render_as 'Select',
        valid_values are defer {
            my $authors = TestApp::Model::AuthorCollection->new();
            $authors->unlimit;
            $authors->order_by( column => 'name' );
            [{
                display_from => 'name',
                value_from   => 'id',
                collection   => $authors,
            }];
        };
};

# Your model-specific methods go here.

1;

