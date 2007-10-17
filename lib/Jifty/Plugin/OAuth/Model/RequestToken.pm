#!/usr/bin/env perl
package Jifty::Plugin::OAuth::Model::RequestToken;
use strict;
use warnings;

use base qw( Jifty::Record );

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

    column used =>
        type is 'boolean',
        default is 'f';

};

sub before_create {
    my ($self, $attr) = @_;
    $attr{valid_until} ||= DateTime->now->add(hours => 1);
}

sub set_authorized {
    my $self = shift;
    $self->set_authorized_by(Jifty->web->current_user->id);
}

sub trade_for_access_token {
    my $self = shift;
    return undef if !$self->authorized;
    return undef if !$self->authorized_by;
    return undef if $self->used;
    return undef if $self->valid_until < DateTime->now;

    my $access_token = Jifty::Plugin::OAuth::Model::AccessToken->new(current_user => Jifty::CurrentUser->superuser);
    my ($ok, $msg) = $access_token->create(user => $self->authorized_by);

    return undef if !$ok;
    return $access_token;
}

1;

