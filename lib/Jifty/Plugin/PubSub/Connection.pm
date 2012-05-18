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

    $self->{subs} = Jifty->subs->retrieve($self->client_id);
    if ( @{ $self->{subs} } ) {
        my @subs = map {$_->{topic}} @{ $self->{subs} };
        $self->{bus} = Jifty->bus->new_listener;
        $self->{bus}->subscribe( $_ )
            for map {Jifty->bus->topic($_)} @subs;
        # Would ->poll for updates here
    }

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

sub receive {
    my $self = shift;
    my $msg = shift;

    return 1 if $self->action_message($msg);
    return;
}

sub action_message {
    my $self = shift;
    my $msg = shift;
    return unless exists $msg->{type}
        and ($msg->{type} || '') eq "action"
            and exists $msg->{class}
                and defined $msg->{class};

    my $class = Jifty->api->qualify($msg->{class});
    unless (Jifty->api->is_allowed($class)) {
        warn "Attempt to call denied action $class: ".Jifty->api->explain($class);
        return 1;
    }
    my $action = Jifty->web->new_action(
        class     => $class,
        arguments => $msg->{arguments} || {},
    );
    $action->validate;
    $action->run if $action->result->success;

    my $result = $action->result->as_hash;
    $result->{type} = "jifty.result";
    $self->send($result);

    return 1;
}

sub disconnect {}

1;
