use warnings;
use strict;
 
package Jifty::Web::Form::Field::DateTime;

use base qw/Jifty::Web::Form::Field/;

=head1 NAME

Jifty::Web::Form::Field::DateTime - Add date pickers to your forms

=head1 METHODS

=head2 classes

Output date fields with the class 'date'

=cut

sub classes {
    my $self = shift;
    return join(' ', 'datetime', ($self->SUPER::classes));
}

1;
