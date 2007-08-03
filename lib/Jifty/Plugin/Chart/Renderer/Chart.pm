use strict;
use warnings;

package Jifty::Plugin::Chart::Renderer::Chart;
use base qw/ Jifty::Plugin::Chart::Renderer /;

use Jifty::YAML;

=head1 NAME

Jifty::Plugin::Chart::Renderer::Chart - A chart renderer using PNG charts

=head1 DESCRIPTION

This is the default chart renderer used by the L<Jifty::Plugin::Chart> plugin. It works by rendering an IMG tag in the HTML output, which then points to a URL which, when dispatched, retrieves the stored configuration and renders the chart using the L<Chart> package.

=head1 METHODS

=head2 render

Implemented the L<Jifty::Plugin::Chart::Renderer/render> method interface.

=cut

sub render {
    my $self = shift;
    my %args = @_;

    # Make sure the type is ready to be used as a class name
    $args{type} = ucfirst lc $args{type};

    # Save the data for retrieval from the session later
    my $chart_id   = Jifty->web->serial;
    my $session_id = 'chart_' . $chart_id;
    Jifty->web->session->set( $session_id => Jifty::YAML::Dump(\%args) );

    # Build up the chart tag
    my $img;
    $img  = qq{<img};
    $img .= qq{ src="/chart/chart/$chart_id"};
    $img .= qq{ class="@{[ join ' ', @{ $args{class} } ]}"};

    my @styles;
    push @styles, "width:$args{width}"   if defined $args{width};
    push @styles, "height:$args{height}" if defined $args{height};

    $img .= qq{ style="@{[ join ';', @styles ]}"} if @styles;
    $img .= qq{/>};
    
    # Output the <img> tag and include the chart's configuration key
    Jifty->web->out($img);

    # Make sure we don't return anything that will get output
    return;
}

=head1 SEE ALSO

L<Jifty::Plugin::Chart>, L<Jifty::Plugin::Chart::Renderer>

=head1 AUTHOR

Andrew Sterling Hanenkamp C<< <andrew.hanenkamp@boomer.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc.

This is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
