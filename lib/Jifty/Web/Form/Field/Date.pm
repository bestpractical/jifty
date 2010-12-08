use warnings;
use strict;
 
package Jifty::Web::Form::Field::Date;

use base qw/Jifty::Web::Form::Field/;

=head1 NAME

Jifty::Web::Form::Field::Date - Add date pickers to your forms

=head1 METHODS

=head2 classes

Output date fields with the class 'date'. If the current user's user object has
a C<calendar_starts_monday> method, and it returns true, the
C<calendar-starts-monday> class is added as well.

=cut

sub classes {
    my $self = shift;
    my $classes = join ' ', $self->SUPER::classes;
    $classes .= ' date';

    if (my $user = Jifty->web->current_user->user_object) {
        $classes .= ' calendar-starts-monday'
            if $user->can('calendar_starts_monday')
            && $user->calendar_starts_monday;
    }

    return $classes;
}

=head2 canonicalize_value

If the value is a DateTime, return just the C<ymd> portion of it.

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
