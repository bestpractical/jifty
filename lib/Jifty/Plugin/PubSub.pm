use strict;
use warnings;

package Jifty::Plugin::PubSub;
use base qw/Jifty::Plugin/;

use AnyMQ;

sub init {
    my $self = shift;
    my %opt  = @_;

    my $anymq = AnyMQ->new_with_traits(
        traits => ['AMQP'],
        host   => 'localhost',
        port   => 5672,
        user   => 'guest',
        pass   => 'guest',
        vhost  => '/',
        exchange => 'events',
        %opt,
    );
    *Jifty::bus = sub { $anymq };
}

1;
