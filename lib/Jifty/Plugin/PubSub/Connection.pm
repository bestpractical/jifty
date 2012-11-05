use strict;
use warnings;

package Jifty::Plugin::PubSub::Connection;

# This is _new rather than new because it should never be called by
# external code
sub _new {
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
    $self->{region_subs} = [];

    for my $sub ( @{ Jifty->subs->retrieve($self->client_id) }) {
        if ( join(" ", keys %{$sub}) eq "topic" ) {
            $self->subscribe( $sub->{topic} );
        } else {
            push @{ $self->{region_subs} }, $sub;
        }
    }

    if ( @{ $self->{region_subs} } ) {
        my @subs = map {$_->{topic}} @{ $self->{region_subs} };
        $self->{region_bus} = Jifty->bus->new_listener;
        $self->{region_bus}->subscribe( $_ )
            for map {Jifty->bus->topic($_)} @subs;
        $self->{region_bus}->poll( sub { $self->region_event( @_ ) } );
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
    my ($type, $data) = @_;
    $data->{type} = $type;
    Jifty->bus->topic("client." . $self->client_id )
        ->publish( $data );
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
    return unless ($msg->{type} || '') eq "jifty.action"
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
    $self->send( "jifty.result" => $result);

    return 1;
}

sub region_event {
    my $self = shift;
    my $event = shift;
    my $type = $event->{type} or return;

    local $Jifty::WEB = $self->web;
    local $Jifty::API = $self->api;
    Jifty::Record->flush_cache if Jifty::Record->can('flush_cache');

    for my $sub ( @{$self->{region_subs}} ) {
        next unless $sub->{topic} eq $type;

        my $content;
        my $region_name;
        eval {
            # So we don't warn about "duplicate region"s
            local Jifty->web->{'regions'} = {};
            local Jifty->web->{'region_stack'} = [];
            # So we don't pick up additional subs
            local Jifty->subs->{region_subs} = [];

            my $region = Jifty::Web::PageRegion->new(
                name      => $sub->{region},
                path      => $sub->{path},
                arguments => $sub->{arguments},
            );
            $region_name = $region->qualified_name;
            Jifty->subs->clear_for( $region_name );

            $region->enter;
            Jifty->handler->buffer->push( private => 1 );
            $region->render_as_subrequest( {
                %{$region->arguments},
                event => $event,
            } );
            $content = Jifty->handler->buffer->pop;
            $region->exit;
            1;
        } or warn "$@";

        $self->send( "jifty.fragment" => {
            region  => $region_name,
            path    => $sub->{path},
            args    => $sub->{arguments},
            content => $content,
            mode    => $sub->{mode},
            element => $sub->{element},
            %{ $sub->{attrs} || {} },
        } );
    }

    # For some reason, AnyMQ makes a queue sub'd to the topic become
    # undef after the poll?  Re-subscribing resolves the issue.
    my @subs = map {$_->{topic}} @{ $self->{region_subs} };
    $self->{region_bus}->subscribe( $_ )
        for map {Jifty->bus->topic($_)} @subs;
}

sub disconnect {
    my $self = shift;
    if ($self->{region_bus}) {
        $self->{region_bus}->timeout(0);
        $self->{region_bus}->unpoll;
        undef $self->{region_bus};
    };
}

1;
