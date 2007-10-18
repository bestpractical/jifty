#!/usr/bin/env perl
package Jifty::Plugin::OAuth::Model::Consumer;
use strict;
use warnings;

use base qw( Jifty::Record );

use Jifty::DBI::Schema;
use Jifty::Record schema {

    # the unique key that identifies a consumer
    column consumer_key =>
        type is 'varchar',
        is distinct,
        is required;

    # a secret used in signing to verify that we have the real consumer (and
    # not just someone who got ahold of the key)
    column secret =>
        type is 'varchar',
        is required;

    # the name of the consumer, e.g. Bob's Social Network
    column name =>
        type is 'varchar',
        is required;

    # the url of the consumer, e.g. http://social.bob/
    column url =>
        type is 'varchar';

};

1;

