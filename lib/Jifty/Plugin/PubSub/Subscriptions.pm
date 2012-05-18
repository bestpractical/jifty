use strict;
use warnings;

package Jifty::Plugin::PubSub::Subscriptions;

sub new {
    my $class = shift;
    my $env = shift;

    my $self = bless {
        store       => {},
        client_id   => undef,
    }, $class;
    return $self;
}

sub reset {
    my $self = shift;
    $self->{client_id} = undef;
}

sub retrieve {
    my $self = shift;
    my $client_id = shift;
    return delete $self->{store}{$client_id} || [];
}

sub client_id {
    my $self = shift;
    return $self->{client_id};
}

sub add {
    my $self = shift;
    my %args = (
        topic => undef,
        @_
    );

    $self->{client_id} ||= "jifty_" . Jifty->web->serial;

    push @{$self->{store}{$self->{client_id}}}, \%args;
}

1;
