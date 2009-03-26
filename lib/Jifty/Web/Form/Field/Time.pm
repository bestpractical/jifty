use warnings;
use strict;
 
package Jifty::Web::Form::Field::Time;

use base qw/Jifty::Web::Form::Field/;

=head1 NAME

Jifty::Web::Form::Field::Time - Add time pickers to your forms

=head1 METHODS

=head2 classes

Output date fields with the class 'time'

=cut

sub classes {
    my $self = shift;
    my $classes = join ' ', $self->SUPER::classes;
    return $classes . ' time';
}

1;
