use strict;
use warnings;

package Jifty::I18N;

=head1 NAME

Jifty::I18N - Internationalization framework for Jifty

=head1 METHODS

=head2 loc

This module exports the C<loc> method, which it inherits from
L<Locale::Maketext::Simple>.

=cut

use base 'Exporter';

our @EXPORT = 'loc';

require Locale::Maketext::Simple;
Locale::Maketext::Simple->import(
    Subclass => '',
    Path     => substr(__FILE__, 0, -3),
    Style    => 'gettext',
    Encoding => 'locale',
);

1;
