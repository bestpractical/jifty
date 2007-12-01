use warnings;
use strict;
 
package Jifty::Web::Form::Field::Date;

use base qw/Jifty::Web::Form::Field/;

=head1 NAME

Jifty::Web::Form::Field::Date - Add date pickers to your forms

=head1 METHODS

=head2 classes

Output date fields with the class 'date'

=cut

sub classes {
    my $self = shift;
    return join(' ', 'date', ($self->SUPER::classes));
}


=head2 handler_allowed HANDLER_NAME

Returns 1 if the handler (e.g. onclick) is allowed.  Undef otherwise.

=cut

sub handler_allowed {
    undef;
}


=head2 canonicalize_value

If the value is a DateTime, return just the ymd portion of it.

=cut

sub canonicalize_value {
    my $self  = shift;
    my $value = $self->current_value;

    if (UNIVERSAL::isa($value, 'DateTime')) {
        $value = $value->ymd;
    }

    return $value;
}


1;
