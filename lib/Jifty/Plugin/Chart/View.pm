use strict;
use warnings;

package Jifty::Plugin::Chart::View;
use Jifty::View::Declare -base;

use IO::String;

=head1 NAME

Jifty::Plugin::Chart::View - Views for the renderers built into the Chart plugin

=head1 TEMPLATES

=head2 chart

This shows a chart using L<Chart>. It expects to find the arguments in the C<args> parameter, which is setup for it in L<Jifty::Plugin::Chart::Dispatcher>.

This will output a PNG file unless there is an error building the chart.

=cut

template 'chart' => sub {
    # Load the arguments
    my $args = get 'args';

    # Use the "type" to determine which class to use
    my $class = 'Chart::' . $args->{type};

    # Load that class or die if it does not exist
    eval "use $class";
    die $@ if $@;

    # Set the output type to the PNG file type
    Jifty->handler->apache->content_type('image/png');

    # Render the chart and output the PNG file generated
    my $fh = IO::String->new;
    my $chart = $class->new( $args->{width}, $args->{height} );
    $chart->png($fh, $args->{data});
    outs_raw( ${ $fh->string_ref } )
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
