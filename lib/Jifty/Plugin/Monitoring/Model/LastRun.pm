use strict;
use warnings;

package Jifty::Plugin::Monitoring::Model::LastRun;

use base qw( Jifty::Record );

use Jifty::DBI::Schema;
use Jifty::Record schema {

    column name =>
        type is 'varchar',
        is distinct,
        is required;

    column last_run =>
        type is 'timestamp',
        filters are 'Jifty::DBI::Filter::DateTime';
};

1;

