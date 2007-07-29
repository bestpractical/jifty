use strict;
use warnings;

package Jifty::Plugin::Chart::Dispatcher;
use Jifty::Dispatcher -base;

use Jifty::YAML;

=head1 NAME

Jifty::Plugin::Chart::Dispatcher - Dispatcher for the chart API plugin

=head1 RULES

=head2 chart/*

Grabs the chart configuration stored in the key indicated in C<$1> and unpacks it using L<YAML>. It then passes it to the L<Jifty::Plugin::Chart::View/chart> template.

=cut

on 'chart/*' => run {
    my $session_id = 'chart_' . $1;

    my $args = Jifty::YAML::Load( Jifty->web->session->get( $session_id ) );
    Jifty->web->session->remove( $session_id );

    last_rule unless defined $args;

    set 'args' => $args;
    show 'chart';
};

=head1 SEE ALSO

L<Jifty::Plugin::Chart::View>

=head1 AUTHOR

Andrew Sterling Hanenkamp E<< <andrew.hanenkamp@boomer.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Boomer Consulting, Inc.

This is free software and may be modified and redistributed under the same terms as Perl itself.

=cut

1;
