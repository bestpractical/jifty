use strict;
use warnings;

package Jifty::Plugin::Chart::Dispatcher;
use Jifty::Dispatcher -base;

use Jifty::YAML;

=head1 NAME

Jifty::Plugin::Chart::Dispatcher - Dispatcher for the chart API plugin

=cut

my %classes = (
    chart       => 'Chart::$TYPE',
    gd_graph    => 'GD::Graph::$TYPE',
    xmlswf      => 'XML::Simple',
);

=head1 RULES

=head2 chart/*/*

Grabs the chart configuration stored in the key indicated in C<$1> and unpacks it using L<YAML>. It then passes it to the correct L<Jifty::Plugin::Chart::View> template.

=cut

on 'chart/*/*' => run {
    my $renderer = $1;

    # No renderer?  Act like a 404.
    last_rule if not defined $classes{$renderer};

    # Create a session ID to lookup the chart configuration
    my $session_id = 'chart_' . $2;

    # Unpack the data and then clear it from the session
    my $args = Jifty::YAML::Load( Jifty->web->session->get( $session_id ) );

    # XXX if there are a lot of charts, this could asplode
    #Jifty->web->session->remove( $session_id );

    # No data? Act like a 404
    last_rule unless defined $args;

    # Request might override width/height:
    $args->{width}  = get 'width'  if get 'width';
    $args->{height} = get 'height' if get 'height';

    # XXX TODO Is there a better way to guess the pixel heights when using CSS
    # heights initially?

    # Remove 'px' from width/height and set to 400/300 if not in pixels
    ($args->{width}  =~ s/px$//) or ($args->{width}  = 400);
    ($args->{height} =~ s/px$//) or ($args->{height} = 300);

    # No zeroes! Ba Ba Blacksheep.
    $args->{width}  ||= 400;
    $args->{height} ||= 300;

    if (my $class = $classes{$renderer}) {
        # Use the "type" to determine which class to use
        $class =~ s/\$TYPE/$args->{type}/g;

        # Load that class or die if it does not exist
        $class->require;

        # Remember the class name for the view
        $args->{class} = $class;
    }

    # Send them on to chart the chart
    set 'args' => $args;
    show "chart/$renderer";
};

=head1 SEE ALSO

L<Jifty::Plugin::Chart::View>

=head1 AUTHOR

Andrew Sterling Hanenkamp C<< <andrew.hanenkamp@boomer.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc.

This is free software and may be modified and redistributed under the same terms as Perl itself.

=cut

1;
