use strict;
use warnings;

package Jifty::Plugin::PubSub::Bus;
use base qw/ AnyMQ /;

=head1 NAME

Jifty::Plugin::PubSub::Bus - AnyMQ class for Jifty

=head1 DESCRIPTION

This class inherits from L<AnyMQ>, and exists to provide a simpler
interface to that module.

=head1 METHODS

=head2 publish I<TOPIC> I<DATA>

Jifty uses the C<type> key of data on the L<AnyMQ> bus to track what
topic the data was originally published on; this method checks that the
provided I<DATA> doesn't attempt to use that key, and warns if it does.
It then publishes the given I<DATA> on the I<TOPIC>.

Roughly equivalent to L<AnyMQ/topic> followed by
L<AnyMQ::Topic/publish>.

=cut

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
