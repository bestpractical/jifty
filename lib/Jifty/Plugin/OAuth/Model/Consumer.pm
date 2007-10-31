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

=head2 table

Consumers are stored in the table C<oauth_consumers>.

=cut

sub table {'oauth_consumers'}

=head2 before_set_last_timestamp

If the new timestamp is different from the last_timestamp, then clear any
nonces we've used. Nonces must only be unique for requests of a given
timestamp.

Note that you should ALWAYS call is_valid_request before updating the
last_timestamp. You should also verify the signature and make sure the request
all went through before updating the last_timestamp. Otherwise an attacker
may be able to create a request with an extraordinarily high timestamp and
screw up the regular consumer.

=cut

sub before_set_last_timestamp {
    my $self = shift;
    my $new_ts = shift;

    # uh oh, looks like sloppy coding..
    if ($new_ts < $self->last_timestamp) {
        die "The new timestamp is LESS than the last timestamp. You forgot to call is_valid_request!";
    }

    # if this is a new timestamp, then flush the nonces
    if ($new_ts != $self->last_timestamp) {
        $self->set_nonces( {} );
    }
}

=head2 is_valid_request TIMESTAMP, NONCE

This will do some sanity checks (as required for security by the OAuth spec).
It will make sure that the timestamp is not less than the latest timestamp for
this consumer. It will also make sure that the nonce hasn't been seen for
this timestamp (very important).

ALWAYS call this method when handling OAuth requests. EARLY.

=cut

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

=head2 made_request TIMESTAMP, NONCE

This method is to be called just before you're done processing an OAuth
request. Parameters were valid, no errors occurred, everything's generally
hunky-dory. This updates the C<last_timestamp> of the consumer, and sets the
nonce as "used" for this new timestamp.

=cut

sub made_request {
    my ($self, $timestamp, $nonce) = @_;
    $self->set_last_timestamp($timestamp);
    $self->set_nonces({ %{$self->nonces}, $nonce => 1 });
}

1;

