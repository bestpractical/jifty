use strict;
use warnings;

package Jifty::Plugin::PubSub::Bus;
use base qw/ AnyMQ /;

sub publish {
    my $self = shift;
    my ($topic, $data) = @_;

    $data ||= {};

    warn "Publish passed data which uses the reserved 'type' key"
        if exists $data->{type};

    $data->{type} = $topic;
    $self->topic( $topic )->publish( $data );
}

1;
