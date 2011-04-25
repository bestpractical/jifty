use strict;
use warnings;

package Doxory::Model::Vote;
use Jifty::DBI::Schema;

use Doxory::Record schema {
    column choice =>
        references Doxory::Model::Choice;

    column voter =>
        references Doxory::Model::User;

    column suggestion =>
        valid are qw/ a b skip /;

    column comments =>
        label is _('Comments?'),
        render as 'textarea';
};

1;
