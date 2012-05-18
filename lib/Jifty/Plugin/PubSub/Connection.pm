use strict;
use warnings;

package Jifty::Plugin::PubSub::Connection;

sub new {
    my $class = shift;
    my $env = shift;

    my $self = bless {}, $class;
    $self->{web} = Jifty::Web->new;
    $self->{web}->request(
        Jifty::Request->promote( Plack::Request->new( $env ) ),
    );
    $self->{web}->response( Jifty::Response->new );
    {
        local $Jifty::WEB = $self->{web};
        Jifty->web->setup_session;
    }

    $self->{api} = Jifty::API->new;
    $self->{listener}  = $env->{'hippie.listener'};
    $self->{client_id} = $env->{'hippie.client_id'};

    $self->subscribe( "client." . $self->client_id );

    return $self;
}

sub web       { shift->{web} }
sub api       { shift->{api} }
sub listener  { shift->{listener} }
sub client_id { shift->{client_id} }

sub connect {}

sub subscribe {
    my $self = shift;
    $self->{listener}->subscribe( $_ )
        for map { Jifty->bus->topic( $_) } @_;
}

sub send {
    my $self = shift;
    Jifty->bus->topic("client." . $self->client_id )
        ->publish( @_ );
}

sub receive {}

sub disconnect {}

1;
