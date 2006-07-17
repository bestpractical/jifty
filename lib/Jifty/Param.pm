use warnings;
use strict;

package Jifty::Param;

=head1 NAME

Jifty::Param - Parameters for Jifty actions

=head1 DESCRIPTION

C<Jifty::Action> is the meat of the L<Jifty> framework; it controls
how form elements interact with the underlying model.  See also
L<Jifty::Action::Record> for data-oriented actions, L<Jifty::Result>
for how to return values from actions.

=cut


use base qw/Jifty::Web::Form::Field/;
use Moose;
has constructor => qw( is rw isa Bool ); # XXX - bad name
no Moose;

1;
