use strict;
use warnings;

package Jifty::Plugin::Chart::Web;

use Scalar::Util qw/ looks_like_number /;

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

This will be one of the following scalar values indicating the kind of chart. A given renderer may not support every type listed here. A renderer might support others in addition to these, but if it supports these it should use these names.

=over

=item points

This is the default value. A scatter plot with each dataset represented using differnet dot styles.

=item lines

A line plot with each dataset presented as separate line.

=item bars

A bar chart with each dataset set side-by-side.

=item stackedbars

A bar chart with each dataset stacked on top of each other.

=item pie

A pie chart with a single dataset representing the values for different pieces of the pie.

=item horizontalbars

A bar chart turned sideways.

=item area

An area chart uses lines to represent each dataset, but the lines are stacked on top of each other with filled areas underneath.

=back

=item width

This is the width the chart should take when rendered. This may be a number, indicating the width in pixels. It may also be any value that would be appropriate for the C<width> CSS property.

Defaults to C<undef>, which indicates that the chart will take on whatever size the box it is in will be. See L</CSS FOR CHARTS>.

=item height

This is the height the chart should take when rendered. This may be a number, indicating the height in pixels. It may also be any value that would be appropriate for the C<height> CSS property.

Defaults to C<undef>, which indicates that the chart will take on whatever size the box it is in will be. See L</CSS FOR CHARTS>.

=item data

An array of arrays containing the data. The first array in the parent array is a list of labels. Each following array is the set of data points matching each label in the first array.

Defaults to no data (i.e., it must be given if anything useful is to happen).

=item class

This allows you to associated an additional class or classes to the element containing the chart. This can be a string containing on or more class names separated by spaces or an array of class names.

=item renderer

This allows you to use a different renderer than the one configured in F<config.yml>. Give the renderer as a class name, which will be initialized for you.

=item options

This is a hash containing additional options to pass to the renderer and are renderer specific. This may include anything that is not otherwise set by one of the other options above.

=back

Here's an example:

  <% Jifty->web->chart(
      type   => 'Pie',
      width  => '100%',
      height => '300px',
      data   => sub {
          [
              [ 2004, 2005, 2006, 2007 ],
              [ 26, 37, 12, 42 ]
          ];
      },
      class => 'visualizeronimicon',
  ) %>

Be sure to output anything returned by the method (unless it returns undef).

=cut

sub chart {
    my $self = shift;
    my ($plugin) = Jifty->find_plugin('Jifty::Plugin::Chart');

    # TODO It might be a good idea to make this config.yml-able
    # Setup the defaults
    my %args = (
        renderer => $plugin->renderer,
        type     => 'points',
        width    => undef,
        height   => undef,
        data     => [],
        class    => [],
        @_,
    );

    # load the renderer
    $args{renderer} = $plugin->init_renderer($args{renderer});

    # canonicalize the width/height
    $args{width}  .= 'px' if looks_like_number($args{width});
    $args{height} .= 'px' if looks_like_number($args{height});

    # canonicalize the type argument (always lowercase)
    $args{type} = lc $args{type};

    # canonicalize the class argument
    if (not ref $args{class}) {
        $args{class} = defined $args{class} ? [ $args{class} ] : [];
    }

    # Add the chart class, which is always present
    push @{ $args{class} }, 'chart';

    # Turn any subs into values returned
    for my $key (keys %args) {
        $args{$key} = $args{$key}->(\%args) if ref $args{$key} eq 'CODE';
    }

    # Call the rendering class' render method
    return $args{renderer}->render(%args);
}

=head1 CSS FOR CHARTS

The chart API allows you to build the charts without explicit pixel widths and heights. In fact, you can not specify C<width> and C<height> and perform the styling in your regular CSS stylesheets by using the "chart" class associated with every chart or by using custom classes with the C<class> argument.

See your renderer class documentation for further details.

=head1 JAVASCRIPT FOR CHARTS

Charts typically require JavaScript to render properly. If the client does not have JavaScript available, the chart may not work or could look very bad. 

If you are using one of the image based renderers like L<Jifty::Plugin::Chart::Renderer::Chart>, it is recommended that you stick with pixel widths if you expect clients with limited or no JavaScript support. 

=head1 SEE ALSO

L<Jifty::Plugin::Chart>, L<Jifty::Plugin::Chart::Renderer>

=head1 AUTHOR

Andrew Sterling Hanenkamp C<< <andrew.hanenkamp@boomer.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc.

This is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
