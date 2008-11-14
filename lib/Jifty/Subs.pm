use warnings;
use strict;

package Jifty::Subs;

use base qw/Jifty::Object/;

use constant new => __PACKAGE__;

=head1 NAME

Jifty::Subs - Configure subscriptions for the current window or session

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



=head1 METHODS

=head2 add PARAMHASH

Add a subscription for the current window or session.

Takes the following parameters

=over

=item class

What class of object shall we subscribe to notifications on

=item queries

An array of queries to match items of class C<class> against. The implementation of C<queries> is dependent on the type of object events are being recorded against

=item mode

How should the fragment sent to the client on matching events be rendered. Valid modes are C<Replace>, C<Bottom> and C<Top>

=item region

The moniker of the region that updates to this subscription should be rendered into

=item render_with

The path of the fragment used to render items matching this subscription

=item effect

The effect to use when showing the region, if any.

=item effect_args

Arguments to the effect

=item remove_effect

The effect to use when removing the old value of the region, if any.

=item remove_effect_args

Arguments to the remove effect

=item coalesce

If multiple events would cause the update of the given region with the
same C<render_with> path, merge them and only render the region once,
with the latest update.

=back

=cut

sub add {
    my $class = shift;
    my $args = {@_};
    unless (Jifty->config->framework('PubSub')->{'Enable'}) {
        $class->log->error("PubSub disabled, but $class->add called");
        return undef;
    }

    $args->{coalesce} = 1 if not exists $args->{coalesce} and $args->{mode} eq "Replace";

    my $id          = ($args->{window_id} || Jifty->web->session->id);
    my $event_class = $args->{class};
    $event_class = Jifty->app_class("Event", $args->{class}) unless $event_class =~ /^Jifty::Event::/;

    my $queries = $args->{queries} || [];
    my $region  = $args->{region};
    my $channel = $event_class->encode_queries(@$queries);
    $args->{attrs}{$_} = delete $args->{$_}
        for grep {exists $args->{$_}} qw/effect effect_args remove_effect remove_effect_args/;

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
            $_->{$channel}{$region} = {
                map { $_ => $args->{$_} }
                    qw/render_with region arguments mode coalesce attrs/
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

    return "$channel!$id!$region";
}

=head2 cancel CHANNEL_ID

Cancels session or window's subscription to CHANNEL_ID

=cut

sub cancel {
    my ($class, $channel_id) = @_;

    unless (Jifty->config->framework('PubSub')->{'Enable'}) {
        $class->log->error("PubSub disabled, but $class->cancel called");
        return undef;
    }

    my ($channel, $id, $region) = split(/!/, $channel_id, 3);
    my ($event_class)  = split(/-/, $channel);

    $id ||= Jifty->web->session->id;

    my $last;
    Jifty->bus->modify(
        "$id-render" => sub {
            delete $_->{$channel}{$region};
            $last = 1 unless %{$_->{$channel}};
        }
    );

    if ($last) {
        Jifty->bus->modify(
            "$event_class-subscriptions" => sub {
                delete $_->{$channel};
            }
        );

        Jifty->bus->modify(
            "$id-subscriber" => sub {
                if ($_) { $_->unsubscribe($channel) }
            }
        );
    }
}

=head2 list [window/sessionid]

Returns a lost of channel ids this session or window is subscribed to.

=cut


sub list {
    my $class = shift;

    unless (Jifty->config->framework('PubSub')->{'Enable'}) {
        $class->log->error("PubSub disabled, but $class->add called");
        return undef;
    }

    my $id   = (shift || Jifty->web->session->id);
    my $subscribe = Jifty->bus->modify( "$id-subscriber" ) or return ();
    return $subscribe->channels;
}

=head2 update_on PARAMHASH

Like L</add>, but provides a sane set of defaults for updating the
current region, based on inspection of the current region's
properties.  C<queries> is set to the region's arguments, and C<class>
is left unspecified.

=cut

sub update_on {
    my $class = shift;

    my $region = Jifty->web->current_region;
    unless ($region) {
        warn "Jifty->subs->update_on called when not in a region";
        return;
    }

    my %args = %{ $region->arguments };
    delete $args{region};
    delete $args{event};

    $class->add(
        queries     => [ \%args ],
        arguments   => \%args,
        mode        => 'Replace',
        region      => $region->qualified_name,
        render_with => $region->path,
        @_,
    );
}

1;
