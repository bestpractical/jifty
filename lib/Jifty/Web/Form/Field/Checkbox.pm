use warnings;
use strict;
 
package Jifty::Web::Form::Field::Checkbox;

use base qw/Jifty::Web::Form::Field/;
__PACKAGE__->mk_accessors(qw/checked value/);

=head2 accessors

Provide C<checked> and C<value> accessors, in addition to
L<Jifty::Web::Form::Field>'s default accessors.  C<value> defaults to
"1".

=cut

sub accessors { shift->SUPER::accessors(), 'checked' , 'value' }

=head2 render_widget

Renders the checkbox widget.

=cut

sub render_widget {
    my $self  = shift;
    my $field =  qq!<input type="hidden" name="@{[ $self->fallback_name ]}" value="0" />\n!;

    $field .= qq!<input!;
    $field .= qq! type="checkbox"!;
    $field .= qq! name="@{[ $self->input_name ]}"!;
    $field .= qq! id="@{[ $self->element_id ]}"!;
    $field .= qq! value="@{[$self->value ||1]}"!;
    $field .= $self->_widget_class;
    $field .= qq! checked="checked"! if ($self->checked or $self->current_value);

    $field .= $self->javascript;
    
    $field .= qq! />\n!;
    Jifty->web->out($field);
    '';
}

=head2 javascript_preempt

By default, javascript (such as onclick handlers) should not actually
prevent browsers from placing the checkmark in the checkbox.

=cut

sub javascript_preempt { return 0; }

1;
