#!/usr/bin/env perl
package Jifty::Plugin::OAuth::Model::RequestToken;
use strict;
use warnings;

use base qw( Jifty::Plugin::OAuth::Token Jifty::Record );

# kludge 1: you cannot call Jifty->app_class within schema {}
my $app_user;
BEGIN { $app_user = Jifty->app_class('Model', 'User') }

use Jifty::DBI::Schema;
use Jifty::Record schema {

    column valid_until =>
        type is 'timestamp',
        filters are 'Jifty::DBI::Filter::DateTime';

    column authorized =>
        type is 'boolean',
        default is 'f';

    # kludge 2: this kind of plugin cannot yet casually refer_to app models
    column authorized_by =>
        type is 'integer';
        #refers_to $app_user;

    column consumer =>
        refers_to Jifty::Plugin::OAuth::Model::Consumer;

    column used =>
        type is 'boolean',
        default is 'f';

    column token =>
        type is 'varchar';

    column secret =>
        type is 'varchar';

    # we use these to make sure we aren't being hit with a replay attack
    column time_stamp =>
        type is 'integer';

    column nonce =>
        type is 'varchar';
};

sub after_set_authorized {
    my $self = shift;
    $self->set_authorized_by(Jifty->web->current_user->id);
}

sub can_trade_for_access_token {
    my $self = shift;

    return (0, "Request token is not authorized")
        if !$self->authorized;

    return (0, "Request token does not have an authorizing user")
        if !$self->authorized_by;

    return (0, "Request token already used")
        if $self->used;

    return (0, "Request token expired")
        if $self->valid_until < DateTime->now;

    return (1, "Request token valid");
}

1;

