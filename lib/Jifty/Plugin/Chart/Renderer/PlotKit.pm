use strict;
use warnings;

package Jifty::Plugin::Chart::Renderer::PlotKit;
use base qw/ Jifty::Plugin::Chart::Renderer /;

use Jifty::YAML;

=head1 NAME

Jifty::Plugin::Chart::Renderer::PlotKit - A chart renderer using PlotKit

=head1 DESCRIPTION

This is an alternate chart renderer used by the L<Jifty::Plugin::Chart> plugin. It works by rendering a <div> tag in the HTML output and some JavaScript in a <script> tag.

=head1 METHODS

=head2 render

Implemented the L<Jifty::Plugin::Chart::Renderer/render> method interface.

=cut

sub render {
    my $self = shift;
    my %args = ( options => {}, @_ );

    # Turn any subs into values returned
    for my $key (keys %args) {
        $args{$key} = $args{$key}->(\%args) if ref $args{$key} eq 'CODE';
    }

    my %types = (
        Lines   => 'line',
        Bars    => 'bar',
        Pie     => 'pie',
    );

    # Make sure the type is ready to be used
    $args{type} = $types{ ucfirst lc $args{type} } || undef;

    if ( not defined $args{type} ) {
        Jifty->log->warn("Unsupported chart type: $args{type}!");
        return;
    }

    $self->_transform_data( \%args );

    # Save the data for retrieval from the session later
    my $chart_id   = 'chart_' . Jifty->web->serial;

    # Output the <canvas> tag and include the chart's JS
    Jifty->web->out(<<"    END_OF_HTML");
<div id="$chart_id" height="$args{height}" width="$args{width}"></div>

<script type="text/javascript">
var plot = function() {
    var plotter = PlotKit.EasyPlot(
        "$args{type}",
        @{[Jifty::JSON::objToJson( $args{options} )]},
        \$("$chart_id"),
        @{[Jifty::JSON::objToJson( $args{data} )]}
    );
};
YAHOO.util.Event.addListener( window, "load", plot );
</script>
    END_OF_HTML

    # Make sure we don't return anything that will get output
    return;
}

sub _transform_data {
    my $self = shift;
    my $args = shift;

    my @data;
    my $labels = shift @{ $args->{data} };

    for ( my $i = 0; $i < @$labels; $i++ ) {
        push @{$args->{options}{xTicks}}, { v => $i, label => $labels->[$i] }
            if defined $labels->[$i];
    }
    
    for my $dataset ( @{ $args->{data} } ) {
        my @ds;
        for ( my $i = 0; $i < @$dataset; $i++ ) {
            # PlotKit can't deal with undefined values
            push @ds, [ $i, defined $dataset->[$i] ? $dataset->[$i] : '0' ];
        }
        push @data, \@ds;
    }

    $args->{data} = \@data;
}

=head1 SEE ALSO

L<Jifty::Plugin::Chart>, L<Jifty::Plugin::Chart::Renderer>

=head1 AUTHOR

Thomas Sibley

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Best Practical Solutions, LLC

This is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
