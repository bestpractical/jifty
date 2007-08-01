use strict;
use warnings;

package Jifty::Plugin::Chart::View;
use Jifty::View::Declare -base;

=head1 NAME

Jifty::Plugin::Chart::View - Views for the renderers built into the Chart plugin

=head1 TEMPLATES

=head2 chart/chart

This shows a chart using L<Chart>. It expects to find the arguments in the C<args> parameter, which is setup for it in L<Jifty::Plugin::Chart::Dispatcher>.

This will output a PNG file unless there is an error building the chart.

=cut

template 'chart/chart' => sub {
    # Load the arguments
    my $args = get 'args';

    # Set the output type to the PNG file type
    Jifty->handler->apache->content_type('image/png');

    # Render the chart and output the PNG file generated
    eval {
        my $chart = $args->{class}->new( $args->{width}, $args->{height} );
        # XXX scalar_png() is undocumented!!! Might bad to rely upon.
        outs_raw($chart->scalar_png($args->{data}));
    };

    # Should have thrown an error if bad stuff happened, handle that
    if ($@) {
        Jifty->log->error("Failed to render chart: $@");
        die $@;
    }
};

=head2 chart/gd_graph

This shows a chart using L<GD::Graph>. It expects to find the arguments in the C<args> parameter, which is setup for it in L<Jifty::Plugin::Chart::Dispatcher>.

This will output a PNG file unless there is an error building the chart.

=cut

template 'chart/gd_graph' => sub {
    # Load the arguments
    my $args = get 'args';

    # Set the output type to the PNG file type
    Jifty->handler->apache->content_type('image/png');

    # Render the chart and output the PNG file generated
    eval {
        my $graph = $args->{class}->new( $args->{width}, $args->{height} );
        my $gd    = $graph->plot($args->{data})
            or die $graph->error;
        outs_raw($gd->png);
    };

    # Should have thrown an error if bad stuff happened, handle that
    if ($@) {
        Jifty->log->error("Failed to render chart: $@");
        die $@;
    }
};

=head1 SEE ALSO

L<Jifty::Plugin::Chart::Dispatcher>

=head1 AUTHOR

Andrew Sterling Hanenkamp C<< <andrew.hanenkamp@boomer.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc.

This is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
