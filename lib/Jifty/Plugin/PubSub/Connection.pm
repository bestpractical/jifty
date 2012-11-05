use strict;
use warnings;

package Jifty::Plugin::PubSub::Connection;

=head1 NAME

Jifty::Plugin::PubSub::Connection - Connection to browser

=head1 DESCRIPTION

This class represents a bidirectional channel between the server and the
web browser.  You may wish to subclass this class as C<YourApp::PubSub>
to override the L</connect>, L</receive>, or L</disconnect> methods.

=head1 METHODS

=cut

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

=head2 web

Returns the constructed L<Jifty::Web> object which is seen as
C<Jifty->web> whenever in the context of this connection's L</connect>,
L</receive>, L</disconnect>, or when page regions are rendered to be
sent over this channel.  This ensures that C<Jifty->web->current_user>
is set whenever it is relevant.

=head2 api

A new L<Jifty::API> object is instantiated for each
L<Jifty::Plugin::PubSub::Connection> object.  You may wish to limit it
to limit which actions can be performed by the web browser.

=head2 listener

The L<AnyMQ::Queue> object which listens to events for the client.

=head2 client_id

Returns a unique identifier associated with this connection.

=cut

sub web       { shift->{web} }
sub api       { shift->{api} }
sub listener  { shift->{listener} }
sub client_id { shift->{client_id} }

=head2 connect

Called when a connection is established from the browser.  By default,
does nothing.

=cut

sub connect {}

=head2 subscribe I<TOPIC> [, I<TOPIC>, ...]

Subscribes the browser to receive messages on the given topics.

=cut

sub subscribe {
    my $self = shift;
    $self->{listener}->subscribe( $_ )
        for map { Jifty->bus->topic( $_) } @_;
}

=head2 send I<TYPE> I<DATA>

Sends an arbitrary message to the browser.  It is not published to the
rest of the message bus.

=cut

sub send {
    my $self = shift;
    my ($type, $data) = @_;
    $data->{type} = $type;
    Jifty->bus->topic("client." . $self->client_id )
        ->publish( $data );
}

=head2 receive I<DATA>

Called when a message is received from the web browser; returns true if
the message was processed, false otherwise.  If you override this
method, be sure you respect this class' return value:

    sub receive {
        my $self = shift;
        my $msg = shift;
        return 1 if $self->SUPER::receive( $msg );
        # ...
    }

=cut

sub receive {
    my $self = shift;
    my $msg = shift;

    return 1 if $self->action_message($msg);
    return;
}

=head2 action_message I<DATA>

Creates, validates, and runs an action if it was received by the client;
called by L</receive>.

=cut

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

=head2 region_event I<EVENT>

Called when one or more regions on the page needs to be rendered and
pushed to the client, as triggered by an event.  The rendered regions
will be passed I<EVENT> as an C<event> variable.  Currently, rendered
regions cannot alter the client's subscription set.

=cut

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

            # XXX TODO: the "first page render" method of storing subs
            # in Jifty->subs doesn't work when we're in the connection
            # context; no-op all such attempts.  We _can_ nominally
            # alter them immediately using $self->subscribe, however;
            # shim in a Jifty->subs which wraps ->add and turns it into
            # what we do in ->_new
            local Jifty->subs->{store} = {};

            my $region = Jifty::Web::PageRegion->new(
                name      => $sub->{region},
                path      => $sub->{path},
                arguments => $sub->{arguments},
            );
            $region_name = $region->qualified_name;

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

=head2 disconnect

Called when the connection to the browser is lost when the browser
switches to a new page.  This is not immediate, but occurs after a
15-second timeout.

=cut

sub disconnect {
    my $self = shift;
    if ($self->{region_bus}) {
        $self->{region_bus}->timeout(0);
        $self->{region_bus}->unpoll;
        undef $self->{region_bus};
    };
}

1;
