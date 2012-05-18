use strict;
use warnings;

package Jifty::Plugin::PubSub::Connection;

sub new {
    my $class = shift;
    my $env = shift;

    my $self = bless {}, $class;

    $self->{listener}  = $env->{'hippie.listener'};
    $self->{client_id} = $env->{'hippie.client_id'};

    return $self;
}

sub listener  { shift->{listener} }
sub client_id { shift->{client_id} }

sub connect {}

sub receive {}

sub disconnect {}

1;
