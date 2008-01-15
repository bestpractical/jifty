use strict;
use warnings;

package TestApp::Model::CanonTest;
use Jifty::DBI::Schema;

use TestApp::Record schema {
   column column_1 => type is 'text';
};

# we want to drop all non-word chars                                           

sub canonicalize_column_1 {
    my $self = shift;
    my $value = shift;

    $value =~ s/\W//g;
    return $value;
}

1;

