use strict;
use warnings;

package Jifty::Plugin::PubSub;
use base qw/Jifty::Plugin/;

use AnyMQ;
use Plack::Builder;
use Web::Hippie::App::JSFiles;
use Jifty::Plugin::PubSub::Connection;

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
          ! );

    $opt{connection} ||= Jifty->app_class({require => 0}, 'PubSub');
    $opt{connection} = 'Jifty::Plugin::PubSub::Connection'
        unless Jifty::Util->try_to_require($opt{connection});
    $self->{connection} = $opt{connection};

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

    Jifty::View->add_trigger(
        body_end => sub { $self->body_end }
    );
}

sub body_end {
    my $self = shift;
    Jifty->web->out( qq|<script type="text/javascript">var hpipe = new Hippie.Pipe(); hpipe.init({path: "/__jifty"})</script>|);
}

sub psgi_app_static {
    my $self = shift;
    my $static_root = $self->static_root;
    builder {
        mount '/'          => Plack::App::File->new(root => $static_root)->to_app;
        mount '/js/pubsub' => Web::Hippie::App::JSFiles->new->to_app;
    };
}

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
                      ||= $self->{connection}->new($env);
                  my $c = $connections{$client_id};

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
