use strict;
use warnings;

package TestApp::JiftyJS::Model::Offer;
use Jifty::DBI::Schema;

use TestApp::JiftyJS::Record schema {
    column name =>
        type is "varchar(255)";

    column is_job =>
        type is "boolean",
        label is _("Job Offer ?");

};

sub current_user_can {
    1;
}

1;

