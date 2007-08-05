use strict;
use warnings;

package Jifty::Plugin::Chart::Renderer::SimpleBars;
use base qw/ Jifty::Plugin::Chart::Renderer /;

=head1 NAME

Jifty::Plugin::Chart::Renderer::SimpleBars - a simple horizontal bar chart

=head1 DESCRIPTION

This is a simple renderer for charts created both as a dead simple way of rendering horizontal bar charts, which can be a very simple way of rendering data, and as a prototype for some other work I'm thinking of doing with the chart plugin.

=head1 OPTIONS

Of the rendering API, this only uses the first dataset given and ignores any others. It also fails if used for any type other than the only one it supports "horizontalbars".

It takes the following options:

=over

=item summary

To maximize the accessibility of your chart, set this to describe the data. This will set the table's summary attribute.

=back

=head1 STYLING

Please be aware that when using this object, you must add background  color to the application CSS file to see the bars.

  div.simple_bars span.bar {
      background-color: black;
  }

=head1 METHODS

=head2 init

Tell Jifty about the CSS and JS files SimpleBars needs.

=cut

sub init {
    Jifty->web->add_javascript('simple_bars.js');
    Jifty->web->add_css('simple_bars.css');
}

=head2 render

Renders a horizontal bar chart. This is done by rendering a table of HTML values, which is then converted to a bar chart by the Javascript added to the response during L</init>.

If JavaScript is not supported by the browser, all the data is presented ina table. They can still read the data, but just not in the most readable form.

=cut

sub render {
    my $self = shift;
    my %args = @_;

    # We only handle horizontalbars, fail on all else
    if ($args{type} ne 'horizontalbars') {
        die 'Sorry, SimpleBars charts only handle horizontalbars chart types.';
    }

    # Create a fresh ID for the chart
    my $chart_id = 'chart_' . Jifty->web->serial;

    # Add the simple_bars class for the JavaScript to find
    push @{ $args{class} }, 'simple_bars';

    # Build the table
    my $table;
    $table  = qq{<table id="$chart_id"};
    $table .= qq{ class="@{[ join ' ', @{ $args{class} } ]}"};
    $table .= qq{ summary="$args{summary}"} if $args{summary};
    $table .= qq{/><tbody>};

    for my $index (0 .. $#{ $args{data}[0] }) {
        my $label = $args{data}[0][$index];
        my $point = $args{data}[1][$index];

        $table .= '<tr>';
        $table .= "<td>@{[ Jifty->web->escape($label) ]}</td>";
        $table .= "<td>@{[ Jifty->web->escape($point) ]}</td>";
        $table .= '</tr>';
    }

    $table .= '</tbody></table>';

    Jifty->web->out($table);

    return;
}

=head1 AUTHOR

Andrew Sterling Hanenkamp, C<< <andrew.hanenkamp@boomer.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc.

This is free software. You may modify and redistribute it under the same terms as Perl itself.

=cut

1
