use strict;
use warnings;

package Jifty::Plugin::Chart::Web;

=head1 NAME

Jifty::Plugin::Chart::Web - Base class to add to Jifty::Web's ISA

=head1 DESCRIPTION

When the L<Jifty::Plugin::Chart> is loaded, this class is added as a base class for L<Jifty::Web> to add the L</chart> method to that class.

=head1 METHODS

=head2 chart

  Jifty->web->out(Jifty->web->chart(%args));

The arguments passed in C<%args> may include:

=over

=item type

This will be one of the following scalar values indicating the kind of chart:

=over

=item Points

This is the default value. A scatter plot with each dataset represented using differnet dot styles.

=item Lines

A line plot with each dataset presented as separate line.

=item Bars

A bar chart with each dataset set side-by-side.

=item StackedBars

A bar chart with each dataset stacked on top of each other.

=item Pie

A pie chart with a single dataset representing the values for different pieces of the pie.

=item HorizontalBars

A bar chart turned sideways.

=back

=item width

The width, in pixels, the chart should take on the page. Defaults to 400.

=item height

The height, in pixels, the chart should take on the page. Defaults to 300.

=item data

An array of arrays containing the data. The first array in the parent array is a list of labels. Each following array is the set of data points matching each label in the first array.

Defaults to no data (i.e., it must be given if anything useful is to happen).

=back

Here's an example:

  <% Jifty->web->chart(
      type   => 'Pie',
      width  => 400,
      height => 300,
      data   => sub {
          [
              [ 2004, 2005, 2006, 2007 ],
              [ 26, 37, 12, 42 ]
          ];
      },
  ) %>

Be sure to output anything returned by the method (unless it returns undef).

=cut

sub chart {
    my $self = shift;
    my ($plugin) = Jifty->find_plugin('Jifty::Plugin::Chart');

    # TODO It might be a good idea to make this config.yml-able
    # Setup the defaults
    my %args = (
        type   => 'points',
        width  => 400,
        height => 300,
        data   => [],
        @_,
    );

    # Turn any subs into values returned
    for my $key (keys %args) {
        $args{$key} = $args{$key}->(\%args) if ref $args{$key} eq 'CODE';
    }

    # Call the rendering plugin's render method
    return $plugin->render(%args);
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
