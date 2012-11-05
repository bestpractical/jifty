use strict;
use warnings;

package Jifty::Plugin::PubSub::Subscriptions;

=head1 NAME

Jifty::Plugin::PubSub::Subscriptions - Manage browser event subscriptions

=head1 DESCRIPTION

This class is a global cache of the outstanding subscriptions of
requests.  When a page is rendered, it may choose to add subscriptions
via L</update_on> or L</add>:

    # Update the current region on an event
    Jifty->subs->update_on( topic => "some_event" );

or:

    # Send this topic of events to the browser
    Jifty->subs->add( topic => "some_event" );

These subscriptions are not done in the I<rendering> request, but must
be stored until the websocket connection occurs later; this class
manages that storage.

The storage is currently an I<in-memory> store which I<does not purge
old subscriptions>.  This means that if a page with subscriptions is
requested 1000 times, but the websocket for them is never established,
those subscriptions will be stored until the server is restarted.  In
the future, these subscriptions may be stored on the session, and
expired in conjunction.

The only expected interaction with this module is via L</update_on> and
L</add>.

=head1 METHODS

=cut

# This is _new rather than new because it is a singleton
sub _new {
    my $class = shift;
    my $env = shift;

    my $self = bless {
        store       => {},
        client_id   => undef,
    }, $class;
    return $self;
}

=head2 reset

Called internally once per request to reset for the next request.

=cut

sub reset {
    my $self = shift;
    $self->{client_id} = undef;
}

=head2 retrieve I<CLIENT_ID>

Returns the data structure of subscriptions for the given I<CLIENT_ID>,
and removes it such that it is not accessible to future requests.

=cut

sub retrieve {
    my $self = shift;
    my $client_id = shift;
    return delete $self->{store}{$client_id} || [];
}


=head2 client_id

Returns the assigned I<CLIENT_ID> of the current connection.  This is
C<undef> if the client has not been assigned any subscriptions yet.

=cut

sub client_id {
    my $self = shift;
    return $self->{client_id};
}

=head2 add topic => I<TOPIC> [, ...]

Adds a subscription.  If only the I<TOPIC> is given, the event will be
passed through to the web browser to interpret.  Otherwise, the
arguments are used similarly to L<Jifty::Web::Element> to determine
which region to update, and how.

=cut

sub add {
    my $self = shift;
    my %args = (
        topic              => undef,
        region             => undef,
        path               => undef,
        arguments          => undef,
        mode               => undef,
        element            => undef,
        effect             => undef,
        effect_args        => undef,
        remove_effect      => undef,
        remove_effect_args => undef,
        @_
    );

    $self->{client_id} ||= "jifty_" . Jifty->web->serial;

    delete $args{$_} for grep {not defined $args{$_}} keys %args;

    $args{attrs}{$_} = delete $args{$_}
        for grep {defined $args{$_}}
            qw/       effect        effect_args
               remove_effect remove_effect_args/;

    push @{$self->{store}{$self->{client_id}}}, \%args;
}

=head2 update_on topic => I<TOPIC> [, ...]

As L</add>, but defaults to refreshing the current region.

=cut

sub update_on {
    my $self = shift;
    my $region = Jifty->web->current_region;
    unless ($region) {
        warn "Jifty->subs->update_on called when not in a region";
        return;
    }

    my %args = %{ $region->arguments };
    delete $args{region};
    delete $args{event};
    $self->add(
        arguments => \%args,
        mode      => 'Replace',
        region    => $region->qualified_name,
        path      => $region->path,
        @_,
    );
}

1;
