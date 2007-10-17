#!/usr/bin/env perl
package Jifty::Plugin::OAuth::Model::AccessToken;
use strict;
use warnings;

use base qw( Jifty::Plugin::OAuth::Token Jifty::Record );

# kludge 1: you cannot call Jifty->app_class within schema {}
my $app_user;
BEGIN { $app_user = Jifty->app_class('Model', 'User') }

use Jifty::DBI::Schema;
use Jifty::Record schema {

    # kludge 2: this kind of plugin cannot yet casually refer_to app models
    column user =>
        type is 'integer';
        #refers_to $app_user;

    column valid_until =>
        type is 'timestamp',
        filters are 'Jifty::DBI::Filter::DateTime';

    column token_secret =>
        type is 'varchar';

    column consumer =>
        refers_to Jifty::Plugin::OAuth::Model::Consumer;

    # we use these to make sure we aren't being hit with a replay attack
    column timestamp =>
        type is 'integer';

    column nonce =>
        type is 'varchar';
};

1;

