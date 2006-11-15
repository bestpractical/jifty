use warnings;
use strict;
 
package Jifty::Web::Form::Field::Textarea;

use base qw/Jifty::Web::Form::Field/;


=head2 accessors

Provide C<rows> and C<cols> accessors, in addition to
L<Jifty::Web::Form::Field>'s default accessors.

=cut

use constant ACCESSORS => qw(rows cols);
sub accessors { shift->SUPER::accessors(), ACCESSORS }
__PACKAGE__->mk_accessors(ACCESSORS);

=head2 render_widget

Renders the textarea widget.

=cut

sub render_widget {
    my $self  = shift;
    my $field;
    $field .= qq!<textarea!;
    $field .= qq! name="@{[ $self->input_name ]}"!;
    $field .= qq! id="@{[ $self->element_id ]}"!;
    $field .= qq! rows="@{[$self->rows || 5 ]}"!;
    $field .= qq! cols="@{[$self->cols || 60]}"!;
    $field .= $self->_widget_class;
    $field .= qq! >!;
    $field .= Jifty->web->escape($self->current_value) if $self->current_value;
    $field .= qq!</textarea>\n!;
    Jifty->web->out($field);
    '';
}

1;
