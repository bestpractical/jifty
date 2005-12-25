use warnings;
use strict;
 
package JFDI::Web::Form::Field::Textarea;

use base qw/JFDI::Web::Form::Field/;

__PACKAGE__->mk_accessors(qw(rows cols));

=head2 accessors

Provide C<rows> and C<cols> accessors, in addition to
L<JFDI::Web::Form::Field>'s default accessors.

=cut

sub accessors { shift->SUPER::accessors(), 'rows', 'cols' }

=head2 render_widget

Renders the textarea widget.

=cut

sub render_widget {
    my $self  = shift;
    my $field;
    $field .= qq!<textarea name="@{[ $self->input_name ]}" rows="@{[$self->rows || 5 ]}" cols="@{[$self->cols || 60]}">!;
    $field .= $self->default_value if $self->default_value;
    $field .= qq!</textarea>\n!;
    JFDI->mason->out($field);
    '';
}

1;
