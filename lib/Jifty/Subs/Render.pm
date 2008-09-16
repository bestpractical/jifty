package Jifty::Subs::Render;
use strict;
use warnings;

=head1 NAME

Jifty::Subs::Render - Helper for subscriptions rendering

=head1 SYNOPSIS

  Jifty::Subs::Render->render($id, $callback);

=head1 DESCRIPTION



=head2 render($id, $callback)

Render all outstanding messges, and call C<$callback> with render
mode, region name, and content.

=cut

sub render {
    my ( $class, $id, $callback ) = @_;
    my $got;

    # # of fragments sent
    my $sent = 0;

    # Get the IPC::PubSub::Subscriber object and do one fetch of all new
    # events it subscribes to, and put those into $got.
    my $subs
        = Jifty->bus->modify( "$id-subscriber", sub { $got = $_ ? $_->get_all : {} } );

    return 0 unless %$got;

    # Now we the render options for those channels (calling ->modify instead
    # of ->fetch because we want to block if someone else is touching it;
    # it's equivalent to ->modify("$id-render", sub { $_ }).
    my $render = Jifty->bus->modify("$id-render");

    my %coalesce;
    while ( my ( $channel, $msgs ) = each(%$got) ) {
        # Channel name is always App::Event::Class-MD5QUERIES
        my $event_class = $channel;
        $event_class =~ s/-.*//;

        unless ( UNIVERSAL::can( $event_class => 'new' ) ) {
            Jifty->log->error("Receiving unknown event $event_class from the Bus");
            $event_class = Jifty->app_class("Event");
        }

        foreach my $rv (@$msgs) {

            # XXX - We don't yet use $timestamp here.
            my ( $timestamp, $msg ) = @$rv;

    return ($sent);
}

=head2 render_single CLASS, MESSAGE, INFO, CALLBACK

Renders a single region, based on the region information in C<INFO>.

            for my $render_info (values %{$render->{$channel}}) {
                my $region      = Jifty::Web::PageRegion->new(
                    name => $render_info->{region},
                    path => $render_info->{render_with},
                );
                delete Jifty->web->{'regions'}{ $region->qualified_name };

                # Finally render the region.  In addition to the user-supplied arguments
                # in $render_info, we always pass the target $region and the event object
                # into its %ARGS.
                my $region_content = '';
                my $event_object   = $event_class->new($msg);
                $region->render_as_subrequest( \$region_content,
                    {   %{ $render_info->{arguments} || {} },
                        event => $event_object,
                        $event_object->render_arguments,
                    }
                );
                $callback->( $render_info->{mode}, $region->qualified_name, $region_content);
                $sent++;
            }
        }
    }
    return ($sent);
}

1;
