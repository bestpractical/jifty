use strict;
use warnings;

package Jifty::Plugin::Chart::Renderer::XMLSWF;
use base qw/ Jifty::Plugin::Chart::Renderer /;

use Jifty::YAML;

=head1 NAME

Jifty::Plugin::Chart::Renderer::XMLSWF - A chart renderer using XML SWF charts

=head1 DESCRIPTION

This chart renderer uses the XML SWF charting tools to render charts.

  Plugins:
    - Chart:
        DefaultRenderer: XMLSWF
        license_key: YOUR_OPTIONAL_LICENSE_KEY

=head1 METHODS

=head2 init

Save the license key, if any

=cut

our $LICENSE = "";

sub init {
    my $self = shift;
    my %args = ( @_ );

    if ( defined $args{license_key} ) {
        $LICENSE = $args{license_key};
    }
}

=head2 render

Implemented the L<Jifty::Plugin::Chart::Renderer/render> method interface.

=cut

sub render {
    my $self = shift;
    my %args = (
        bgcolor => '#ffffff',
        wmode   => 'transparent',
        @_
    );

    # Conversion from generic types to XML SWF types -- incomplete
    my %types = (
        'bars'           => 'column',
        'stackedbars'    => 'stacked column',
        'horizontalbars' => 'bar',
        'stackedhorizontalbars' => 'stacked bar',
        'lines'          => 'line',
        'pie'            => '3d pie',
        'points'         => 'scatter',
    );

    # Make sure the type is ready to be used
    $args{type} = $types{ $args{type} } || undef;

    # Kill the "px" unit
    $args{width} =~ s/px$//;
    $args{height} =~ s/px$//;

    # Save the data for retrieval from the session later
    my $chart_id   = Jifty->web->serial;
    my $session_id = 'chart_' . $chart_id;
    Jifty->web->session->set( $session_id => Jifty::YAML::Dump(\%args) );

    # Build up the chart tag
    my $src = '/static/flash/xmlswf/charts.swf?';

    my $query = Jifty->web->query_string(
                    library_path => '/static/flash/xmlswf/charts_library',
                    xml_source   => "/chart/xmlswf/$chart_id",
                    license      => $LICENSE
                );
    $query =~ s/;/&/g;
    $src .= $query;

    my $tags = {
        embed => {
            src             => $src,
            quality         => 'high',
            bgcolor         => $args{bgcolor},
            width           => $args{width},
            height          => $args{height},
            name            => $session_id,
            wmode           => $args{wmode},
            type            => 'application/x-shockwave-flash',
            swLiveConnect   => 'true',
            pluginspage     => 'http://www.macromedia.com/go/getflashplayer',
        },
        object => {
            classid     => 'clsid:D27CDB6E-AE6D-11cf-96B8-444553540000',
            codebase    => 'http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=6,0,0,0',
            width       => $args{width},
            height      => $args{height},
            id          => $session_id,
            class       => join( ' ', @{$args{class}} ),
        },
        params  => {
            movie   => $src,
            quality => 'high',
            bgcolor => $args{bgcolor},
            wmode   => $args{wmode},
        },
    };

    my $html = "<div>\n";
    $html .= "<object";
    $html .= qq[ $_="@{[$tags->{object}{$_}]}"]
        for keys %{ $tags->{object} };
    $html .= ">\n";

    $html .= qq[<param name="$_" value="@{[$tags->{params}{$_}]}" />\n] # /damn vim
        for keys %{ $tags->{params} };

    $html .= "<embed";
    $html .= qq[ $_="@{[$tags->{embed}{$_}]}"]
        for keys %{ $tags->{embed} };
    $html .= " />\n";
    $html .= "</object>\n";
    $html .= "</div>\n";

    # Output the HTML and include the chart's configuration key
    Jifty->web->out($html);

    # Make sure we don't return anything that will get output
    return;
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
