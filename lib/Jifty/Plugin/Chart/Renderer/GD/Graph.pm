use strict;
use warnings;

package Jifty::Plugin::Chart::Renderer::GD::Graph;
use base qw/ Jifty::Plugin::Chart::Renderer /;

=head1 NAME

Jifty::Plugin::Chart::Renderer::GD::Graph - A chart renderer using GD::Graph

=head1 SYNOPSIS

In F<config.yml>:

  Plugins:
    - Chart:
        renderer: Jifty::Plugin::Chart::Renderer::GD::Graph

=head1 DESCRIPTION

This is a chart renderer that uses L<GD::Graph> to build charts.

=head1 METHODS

=head2 init

Adds the F<chart_img_behaviour.js> script to those loaded.

=cut

sub init {
    Jifty->web->add_javascript('chart_img_behaviour.js');
}

=head2 render

Renders an IMG tag referring to the L<GD::Graph> image view.

=cut

sub render {
    my $self = shift;
    my %args = @_;

    # Convert the type to lowercase
    $args{type} = lc $args{type};

    # Save the data for retrieval from the session later
    my $chart_id   = Jifty->web->serial;
    my $session_id = 'chart_' . $chart_id;
    Jifty->web->session->set( $session_id => Jifty::YAML::Dump(\%args) );

    # Build up the chart tag
    my $img;
    $img  = qq{<img};
    $img .= qq{ src="/chart/gd_graph/$chart_id"};
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

=head1 AUTHOR

Andrew Sterling Hanenkamp C<< <andrew.hanenkamp@boomer.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc.

This is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
