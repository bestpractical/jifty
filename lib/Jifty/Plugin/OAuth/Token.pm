#!/usr/bin/env perl
package Jifty::Plugin::OAuth::Token;
use strict;
use warnings;
use Scalar::Util 'blessed';

# this just provides some helper methods for both token classes to use

sub generate_token {
    return join '', map { unpack('H2', chr(int rand 256)) } 1..10;
}

sub before_create {
    my ($self, $attr) = @_;

    # check if we're seeing a replay attack
    my $token = $self->new(current_user => Jifty::CurrentUser->superuser);
    $token->load_by_cols(nonce => $attr->{nonce}, time_stamp => $attr->{time_stamp}, consumer => $attr->{consumer});
    if ($token->id) {
        die "Duplicate nonce ($attr->{nonce}) and timestamp ($attr->{time_stamp}) from consumer ".$attr->{consumer}->name.". Possibly a replay attack.";
    }

    # check to see if the timestamp for this consumer is larger than any previous
    my $tokens = (blessed($self).'Collection')->new(current_user => Jifty::CurrentUser->superuser);
    $tokens->limit(column => 'consumer', value => $attr->{consumer});
    $tokens->limit(column => 'time_stamp', value => $attr->{time_stamp}, operator => '>');
    if ($tokens->count) {
        die "Got a timestamp from consumer ".$attr->{consumer}->name." that was smaller than ".$tokens->count." previous timestamps.";
    }

    # attempt 20 times to create a unique token string
    for (1..20) {
        $attr->{token} = generate_token();
        my $token = $self->new(current_user => Jifty::CurrentUser->superuser);
        $token->load_by_cols(token => $attr->{token});
        last if !$token->id;
        delete $attr->{token};
    }
    if (!defined $attr->{token}) {
        die "Failed 20 times to create a unique token. Giving up.";
        return;
    }

    # generate a secret. need not be unique, just hard to guess
    $attr->{secret} = generate_token();

    # default the lifetime of this token to 1 hour
    $attr->{valid_until} ||= DateTime->now->add(hours => 1);

    return 1;
}

1;

