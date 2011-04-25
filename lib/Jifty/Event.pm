use warnings;
use strict;

package Jifty::Event;

use Jifty::YAML;
use Digest::MD5 qw(md5_hex);
use vars qw/%PUBLISHER/;

=head1 NAME

Jifty::Event - Event objects for publish/subscribe communication

=head1 DESCRIPTION

An event object from the Jifty::PubSub stream.

=head1 METHODS

=head2 new($payload)

Constructor.  Takes any kind of payload and blesses a scalar reference to it
into an Event object.

=cut

sub new {
    my $class   = shift;
    my $payload = shift;
    bless \$payload, $class;
}

=head2 publish()

Inserts the event into the pubsub stream.  If Jifty is configured into
synchronous republishing, then this method runs a C<republish> on itself
with all current subscriptions implicitly.  If not, it's simply inserted
into its main channel for asynchronous republishing later.  

=cut

sub publish {
    my $self  = shift;
    my $class = ref($self) || $self;

    return undef unless (Jifty->config->framework('PubSub')->{'Enable'});

    # Always publish to the main stream (needed for async & debugging)
    # if ($ASYNC || $DEBUGGING) {
    #    ($PUBLISHER{$class} ||= Jifty->bus->new_publisher($class))->msg($$self);
    #    return;
    # }

    # Synchronized auto-republishing
    # TODO - Prioritize current-user subscriptions first?
    my $subscriptions = Jifty->bus->modify("$class-subscriptions") || {};
    while (my ($channel, $queries) = each %$subscriptions) {
        if ($self->filter(@$queries)) {
            ($PUBLISHER{$channel} ||= Jifty->bus->new_publisher($channel))->msg($$self);
        }
    }
}

=head2 filter(@query)

Takes multiple class-specific queries, which are evaluated in order by calling L</match>.

=cut

sub filter {
    my $self = shift;
    $self->match($_) or return 0 for @_;
    return 1;
}

=head2 republish(@query)

Run C<filter> with the queries; if they all succeed, the event is republished
into that query-specific channel.

=cut

sub republish {
    my $self = shift;
    $self->filter(@_) or return;

    my $channel = $self->encode_queries(@_);
    ($PUBLISHER{$channel} ||= Jifty->bus->new_publisher($channel))->msg($$self);
}


=head2 encode_queries(@query)

Encode queries into some sort of canonical MD5 encoding.

=cut

sub encode_queries {
    my $self    = shift;
    my $class   = ref($self) || $self;
    return $class unless @_;

    return $class . '-' . md5_hex(join('', sort map { Jifty::YAML::Dump($_) } @_));
}


=head2 match($query)

Takes a class-specific query and returns whether it matches.

You almost always want to override this; the default implementation
simply always return true;

=cut

sub match {
    1;
}

=head2 render_arguments()

A list of additional things to push into the C<%ARGS> of the region that
is about to render this event; see L<Jifty::Subs::Render> for more information.

=cut

sub render_arguments {
    ();
}

=head2 data()

This event's payload as a scalar value.

=cut

sub data {
    ${$_[0]}
}


1;
