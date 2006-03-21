use warnings;
use strict;
 
package Jifty::Web::Form::Field::Date;

use base qw/Jifty::Web::Form::Field/;

=head2 classes

Output date fields with the class 'date'

=cut

sub classes {
    my $self = shift;
    return join(' ', 'date', ($self->SUPER::classes));
}

1;
