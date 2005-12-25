use warnings;
use strict;
 
package Jifty::Web::Form::Field::Textarea;

use base qw/Jifty::Web::Form::Field/;

__PACKAGE__->mk_accessors(qw(rows cols));

=head2 accessors

Provide C<rows> and C<cols> accessors, in addition to
L<Jifty::Web::Form::Field>'s default accessors.

=cut

sub accessors { shift->SUPER::accessors(), 'rows', 'cols' }

=head2 render_widget

Renders the textarea widget.

=cut

sub render_widget {
    my $self  = shift;
    my $field;
    $field .= qq!<textarea!;
    $field .= qq! name="@{[ $self->input_name ]}"!;
    $field .= qq! id="@{[ $self->input_name ]}"!;
    $field .= qq! rows="@{[$self->rows || 5 ]}"!;
    $field .= qq! cols="@{[$self->cols || 60]}"!;
    $field .= $self->_widget_class;
    $field .= qq! >!;
    $field .= $self->current_value if $self->current_value;
    $field .= qq!</textarea>\n!;
    Jifty->mason->out($field);
    '';
}

1;
