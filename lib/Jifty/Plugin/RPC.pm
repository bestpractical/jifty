use strict;
use warnings;

package Jifty::Plugin::RPC;
use base qw/Jifty::Plugin/;

use AnyEvent::RabbitMQ::RPC;

sub prereq_plugins { 'PubSub' }

our $VERSION = '0.5';

our $RPC;
sub init {
    my $self = shift;
    my %opt  = @_;

    $RPC = AnyEvent::RabbitMQ::RPC->new(
        serialize => "Storable",
        connection => Jifty->bus->_rf,
    );

    *Jifty::rpc = sub { $RPC };
}

1;
