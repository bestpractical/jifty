#!/usr/bin/env perl
package TestApp::Plugin::Attributes::Model::Song;
use strict;
use warnings;

use Jifty::Plugin::Attributes::Mixin::Attributes;
use Jifty::DBI::Schema;
use Jifty::Record schema {
    column 'name' =>
        type is 'text',
        is mandatory;

    column 'artist' =>
        type is 'text',
        is mandatory;

    column 'album' =>
        type is 'text',
        is mandatory;
};

our %rights;

sub current_user_can {
    my $self = shift;
    my $right = shift;
    my %args = @_;

    return $rights{$right} if exists $rights{$right};

    $self->SUPER::current_user_can($right, @_);
}

sub set_right {
    my $self = shift;
    my $right = shift;
    my $val = shift;

    return delete $rights{$right} if !defined($val);
    $rights{$right} = $val;
}

1;

