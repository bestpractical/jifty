use strict;
use warnings;

package Jifty::Plugin::RPC;
use base qw/Jifty::Plugin/;

=head1 NAME

Jifty::Plugin::RPC - Use AMQP for RPC

=head1 SYNOPSIS

    Jifty->rpc->call( name => "remote-method" );

=head1 DESCRIPTION

L<Jifty::Plugin::PubSub> interfaces with an L<AnyEvent::RabbitMQ>
connection to provide a message bus.  This provides C<Jifty->rpc> which
implements an L<AnyEvent::RabbitMQ::RPC> using that connection; see that
module for complete documentation.

=head1 METHODS

=head2 prereq_plugins

Use of this plugin requires (or implicitly loads, if missing) the
L<Jifty::Plugin::PubSub> plugin.

=cut

use AnyEvent::RabbitMQ::RPC;

sub prereq_plugins { 'PubSub' }

our $VERSION = '0.5';

=head2 init

This plugin has one configuration option, C<serialize>, which defaults
to C<Storable>.  See L<AnyEvent::RabbitMQ::RPC> for documentation on the
possible alternatives.

=cut

our $RPC;
sub init {
    my $self = shift;
    my %opt  = (
        serialize => "Storable",
        @_,
    );

    $RPC = AnyEvent::RabbitMQ::RPC->new(
        serialize => $opt{serialize},
        connection => Jifty->bus->_rf,
    );

    *Jifty::rpc = sub { $RPC };
}

1;
