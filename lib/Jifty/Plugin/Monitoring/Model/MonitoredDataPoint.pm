use strict;
use warnings;

package Jifty::Plugin::Monitoring::Model::MonitoredDataPoint;

use base qw( Jifty::Record );

use Jifty::DBI::Schema;
use Jifty::Record schema {

    column category =>
        type is 'varchar',
        is required;

    column sample_name =>
        type is 'varchar',
        is required;

    column value =>
        type is 'varchar',
        is required;

    column sampled_at =>
        type is 'datetime',
        filters are 'Jifty::DBI::Filter::DateTime';
};

1;

