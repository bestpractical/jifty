use strict;
use warnings;

package Jifty::I18N;

=head1 NAME

Jifty::I18N - Internationalization framework for Jifty

=head1 METHODS

=head2 C<loc> /  C<_>

This module exports the C<loc> method, which it inherits from
L<Locale::Maketext::Simple>. Jifty aliases this method to C<_()> for 
your convenience.

=cut


use Locale::Maketext::Simple (
    Path        => [Jifty->config->framework('PoDir'),  Jifty->config->framework('DefaultPoDir')],
    Style       => 'gettext',
    Decode      => 1,
);

# Allow _() everywhere to loc
*_ = \&loc;

1;
