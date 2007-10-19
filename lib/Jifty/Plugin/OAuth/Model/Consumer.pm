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

    column rsa_key =>
        type is 'varchar',
        hints are 'This is only necessary if you want to support RSA-SHA1 signatures';

    # we use these to make sure we aren't being hit with a replay attack
    column last_timestamp =>
        type is 'integer',
        is required,
        default is 0;

    column nonces =>
        type is 'blob',
        filters are 'Jifty::DBI::Filter::Storable';
};

sub before_set_last_timestamp {
    my $self = shift;
    my $new_ts = shift;

    # if this is a new timestamp, then flush the nonces
    if ($new_ts != $self->last_timestamp) {
        $self->set_nonces( {} );
    }
}

sub is_valid_request {
    my ($self, $timestamp, $nonce) = @_;
    return (0, "Timestamp nonincreasing.")
        if $timestamp < $self->last_timestamp;
    return 1 if $timestamp > $self->last_timestamp;

    # if this is the same timestamp as the last, we must check that the nonce
    # is unique across the requests of these timestamps
    return (0, "Already used this nonce.")
        if defined $self->nonces->{$nonce};

    return 1;
}

sub made_request {
    my ($self, $timestamp, $nonce) = @_;
    $self->set_last_timestamp($timestamp);
    $self->nonces->{$nonce} = 1;
}

1;

