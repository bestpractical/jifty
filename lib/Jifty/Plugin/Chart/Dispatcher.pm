use strict;
use warnings;

package Jifty::Plugin::Chart::Dispatcher;
use Jifty::Dispatcher -base;

use Jifty::YAML;

=head1 NAME

Jifty::Plugin::Chart::Dispatcher - Dispatcher for the chart API plugin

=head1 RULES

=head2 chart/chart/*

Grabs the chart configuration stored in the key indicated in C<$1> and unpacks it using L<YAML>. It then passes it to the L<Jifty::Plugin::Chart::View/chart> template.

=cut

on 'chart/chart/*' => run {
    # Create a session ID to lookup the chart configuration
    my $session_id = 'chart_' . $1;

    # Unpack the data and then clear it from the session
    my $args = Jifty::YAML::Load( Jifty->web->session->get( $session_id ) );
    Jifty->web->session->remove( $session_id );

    # No data? Act like a 404
    last_rule unless defined $args;

    # Use the "type" to determine which class to use
    my $class = 'Chart::' . $args->{type};

    # Load that class or die if it does not exist
    $class->require;

    # Remember the class name for the view
    $args->{class} = $class;

    # Send them on to chart the chart
    set 'args' => $args;
    show 'chart/chart'
};

=head2 chart/gd_graph/*

Grabs the chart configuration stored in the key indicated in C<$1> and unpacks it using L<YAML>. It then passes it to the L<Jifty::Plugin::Chart::View/chart> template.

=cut

on 'chart/gd_graph/*' => run {
    # Create a session ID to lookup the chart configuration
    my $session_id = 'chart_' . $1;

    # Unpack the data and then clear it from the session
    my $args = Jifty::YAML::Load( Jifty->web->session->get( $session_id ) );
    Jifty->web->session->remove( $session_id );

    # No data? Act like a 404
    last_rule unless defined $args;

    # Use the "type" to determine which class to use
    my $class = 'GD::Graph::' . $args->{type};

    # Load that class or die if it does not exist
    $class->require;

    # Remember the class name for the view
    $args->{class} = $class;

    # Send them on to chart the chart
    set 'args' => $args;
    show 'chart/gd_graph'
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
