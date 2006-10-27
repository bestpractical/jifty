use warnings;
use strict;

package Jifty::Subs;


use constant new => __PACKAGE__;

=head1 NAME

Jifty::Subs - 

=head1 SYNOPSIS

 my $sid = Jifty->subs->add(
    class       => 'Tick',
    queries     => [{ like => '9' }],
    mode        => 'Replace',
    region      => "clock-time",
    render_with => '/fragments/time',
 );
 Jifty->subs->cancel($sid);

 my @sids = Jifty->subs->list;

=head1 DESCRIPTION



=cut

sub add {
    my $class = shift;
    my $args = {@_};
   unless (Jifty->config->framework('PubSub')->{'Enable'}) {
        Jifty->log->error("PubSub disabled, but $class->add called");
        return undef
    }

    my $id          = ($args->{window_id} || Jifty->web->session->id);
    my $event_class = join('::' =>
        Jifty->config->framework("ApplicationClass"),
        'Event',
        $args->{class},
    );

    my $queries = $args->{queries} || [];
    my $channel = $event_class->encode_queries(@$queries);

    # The ->modify here is calling into the callback sub{...} with
    # the previous value of $_, that is a hashref of channels to
    # queries associated with those channels.  The callback then
    # massages it to add a new channel/queries mapping; the value
    # of $_ at the end of the callback is then atomically updated
    # into the message bus under the same key.
    Jifty->bus->modify(
        "$event_class-subscriptions" => sub {
            $_->{$channel} = $queries;
        }
    );

    # The per-window/session ($id) rendering information ("$id-render")
    # contains a hash from subscribed channels to rendering information,
    # including the frament, region, argument and ajax updating mode.
    Jifty->bus->modify(
        "$id-render" => sub {
            $_->{$channel} = {
                map { $_ => $args->{$_} }
                    qw/render_with region arguments mode/
            };
        }
    );

    # We create/update a IPC::PubSub::Subscriber object for this $id,
    # and have it subscribe to the channel that we're adding here.
    Jifty->bus->modify(
        "$id-subscriber" => sub {
            if   ($_) { $_->subscribe($channel) }
            else      { $_ = Jifty->bus->new_subscriber($channel) }
        }
    );

    return "$channel!$id";
}

sub cancel {
    my ($class, $channel_id) = @_;

   unless (Jifty->config->framework('PubSub')->{'Enable'}) {
        Jifty->log->error("PubSub disabled, but $class->add called");
        return undef
    }

    my ($channel, $id) = split(/!/, $channel_id, 2);
    my ($event_class)  = split(/-/, $channel);

    $id ||= Jifty->web->session->id;

    Jifty->bus->modify(
        "$event_class-subscriptions" => sub {
            delete $_->{$channel};
        }
    );

    Jifty->bus->modify(
        "$id-render" => sub {
            delete $_->{$channel}
        }
    );

    Jifty->bus->modify(
        "$id-subscriber" => sub {
            if ($_) { $_->unsubscribe($channel) }
        }
    );
}

sub list {
    my $self = shift;

   unless (Jifty->config->framework('PubSub')->{'Enable'}) {
        Jifty->log->error("PubSub disabled, but $self->add called");
        return undef
    }

    my $id   = (shift || Jifty->web->session->id);
    my $subscribe = Jifty->bus->modify( "$id-subscriber" ) or return ();
    return $subscribe->channels;
}

1;
