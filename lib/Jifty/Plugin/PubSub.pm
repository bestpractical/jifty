use strict;
use warnings;

package Jifty::Plugin::PubSub;
use base qw/Jifty::Plugin/;

=head1 NAME

Jifty::Plugin::PubSub - Event-based publish/subscribe framework

=head1 SYNOPSIS

In F<etc/config.yml>:

    Plugins:
      - PubSub: {}

In a region:

    Jifty->subs->update_on( topic => "some_event" );

In a model:

    Jifty->bus->publish( "some_event" );

=head1 DESCRIPTION

=head2 Generating events

The most basic aspect of event-based communication is the publishing of
messages.  This is done via:

    Jifty->bus->publish( "some_event" => {
        some_key  => "data",
    });

This notifies all subscribers of the C<some_event> class with the
arbitrary payload specified. See L<AnyMQ> for more details of the
backend data bus.  The C<type> key of the data provided is reserved for
internal routing.


=head2 Consuming events outside the webserver

C<<Jifty->bus>> is an L<AnyMQ> bus; as such, the standard ways of
consuming apply here:

    my $listen = Jifty->bus->new_listener;
    $listen->subscribe( Jifty->bus->topic("some_event") );
    $listen->poll( sub {
        my ($data) = @_;
        warn "Got some event with " . $data->{some_key};
    }
    # Loop forever
    AE::cv->recv;


=head2 Pushing updated regions to the client

A region can request that it should be updated in the client when an
event is received.  At the most basic, this is done via:

    Jifty->subs->update_on( topic => "some_event" );

Events may trigger arbitrary other region updates, using:

    Jifty->subs->add(
        topic  => "some_event",
        region => "...",
        path   => "...",
        # Any other arguments from Jifty::Form::Element
    );

When a region is rendered because it was triggered by an event, it will
be passed the triggering event in an C<event> variable.


=head2 Running javascript in the client in response to events

You may also subscribe the web browser directly to events.  This is done
by calling C<Jifty->subs->add> with no region-relevant arguments, merely
the C<topic>:

    Jifty->subs->add( topic => $_ ) for qw/ some_event other_event /;

Once the browser is subscribed, the events will be made available via
the global C<pubsub> object in javascript, and can be consumed via
C<bind>:

    jQuery(pubsub).bind("message.some_event", function (event, data) {
        alert(data.some_key);
    }

=head2 Sending messages from javascript

From javascript in the client, you may also send information back to the
server via the global C<pubsub> object:

    pubsub.send({type: 'something', data: 'here'}});

In order to act on these responses, create a C<YourApp::PubSub> which
inherits from L<Jifty::Plugin::PubSub::Connection>, and override
L<Jifty::Plugin::PubSub::Connection/receive>:

    package YourApp::PubSub;
    use base qw/ Jifty::Plugin::PubSub::Connection /;
    sub receive {
        my $self = shift;
        my $msg = shift;
        return 1 if $self->SUPER::receive( $msg );
        warn "Got some message from the client: " . $msg->{data};
        return 1;
    }

Note that, for security reasons, this communication from the web browser
is B<not> published to the Jifty event bus (though you may opt to
republish them there so manually).

=cut

use AnyMQ;
use Plack::Builder;
use Web::Hippie::App::JSFiles;
use Jifty::Plugin::PubSub::Bus;
use Jifty::Plugin::PubSub::Connection;
use Jifty::Plugin::PubSub::Subscriptions;

our $VERSION = '0.5';

=head1 METHODS

=head2 init

When initializing the plugin, it accepts any arguments that
L<AnyMQ/new_with_traits> accepts.

=cut

sub init {
    my $self = shift;
    my %opt  = @_;

    Jifty->web->add_javascript(
        qw!
              pubsub/DUI.js
              pubsub/Stream.js
              pubsub/hippie.js
              pubsub/hippie.pipe.js
              pubsub/jquery.ev.js
              pubsub.js
          ! );

    $opt{connection} ||= Jifty->app_class({require => 0}, 'PubSub');
    $opt{connection} = 'Jifty::Plugin::PubSub::Connection'
        unless Jifty::Util->try_to_require($opt{connection});
    $self->{connection} = delete $opt{connection};

    my $anymq = Jifty::Plugin::PubSub::Bus->new_with_traits(
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

    my $subs = Jifty::Plugin::PubSub::Subscriptions->_new;
    *Jifty::subs = sub { $subs };

    Jifty::View->add_trigger(
        body_end => sub { $self->body_end }
    );
}

=head2 new_request

Part of the L<Jifty::Plugin> interface; clears out the
L<Jifty::Plugin::PubSub::Subscriptions> on every request.

=cut

sub new_request {
    Jifty->subs->reset;
}

=head2 body_end

Part of the L<Jifty::Plugin> interface; appends a snippet of javascript
to start the client-side websocket.

=cut

sub body_end {
    my $self = shift;
    my $client_id = Jifty->subs->client_id || "";
    $client_id = "'$client_id'" if $client_id;
    Jifty->web->out( qq|<script type="text/javascript">pubsub_init($client_id)</script>|);
}

=head2 psgi_app_static

Part of the L<Jifty::Plugin> interface; provides the required static
javascript.

=cut

sub psgi_app_static {
    my $self = shift;
    my $static_root = $self->static_root;
    builder {
        mount '/'          => Plack::App::File->new(root => $static_root)->to_app;
        mount '/js/pubsub' => Web::Hippie::App::JSFiles->new->to_app;
    };
}

=head2 wrap

Part of the L<Jifty::Plugin> interface; wraps the application to provide
websocket support, via L<Web::Hippie>, and binds it to the L<AnyMQ> bus
via L<Web::Hippie::Pipe>.

=cut

sub wrap {
    my $self = shift;
    my $app = shift;

    my %connections;
    builder {
        mount '/__jifty/_hippie' => builder {
            enable "+Web::Hippie";
            enable "+Web::Hippie::Pipe", bus => Jifty->bus;
            sub { my $env = shift;
                  my $listener  = $env->{'hippie.listener'}; # AnyMQ::Queue
                  my $client_id = $env->{'hippie.client_id'}; # client id

                  $connections{$client_id}
                      ||= $self->{connection}->_new($env);
                  my $c = $connections{$client_id};

                  local $Jifty::WEB = $c->web;
                  local $Jifty::API = $c->api;
                  Jifty::Record->flush_cache if Jifty::Record->can('flush_cache');

                  my $path = $env->{PATH_INFO};
                  if ($path eq "/new_listener") {
                      $c->connect;
                  } elsif ($path eq "/message") {
                      $c->receive($env->{'hippie.message'});
                  } elsif ($path eq "/error") {
                      delete $connections{$client_id};
                      $c->disconnect;
                  }
            };
        };

        mount '/' => $app;
    };
}

1;
