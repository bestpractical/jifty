use warnings;
use strict;
 
package Jifty::Web::Form::Field::Textarea;

use base qw/Jifty::Web::Form::Field/;

__PACKAGE__->mk_accessors(qw(rows cols));

=head1 NAME

Jifty::Web::Form::Field::Textarea - Add a multiline text field to your forms

=head1 METHODS

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
    $field .= qq! id="@{[ $self->element_id ]}"!;
    $field .= qq! title="@{[ $self->title ]}"! if ($self->title);
    $field .= qq! rows="@{[$self->rows || 5 ]}"!;
    $field .= qq! cols="@{[$self->cols || 60]}"!;
    $field .= $self->_widget_class;
    $field .= $self->javascript;
    $field .= qq! >!;
    $field .= Jifty->web->escape($self->current_value) if $self->current_value;
    $field .= qq!</textarea>\n!;
    Jifty->web->out($field);
    '';
}

=head2 handler_allowed HANDLER_NAME

Returns 1 if the handler (e.g. onclick) is allowed.  Undef otherwise.

=cut

sub handler_allowed {
    my $self = shift;
    my ($handler) = @_;

    return $self->SUPER::handler_allowed($handler) ||
           {onselect => 1}->{$handler};

}


1;
