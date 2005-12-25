use warnings;
use strict;
 
package Jifty::Web::Form::Field::Checkbox;

use base qw/Jifty::Web::Form::Field/;

=head2 render_widget

Renders the checkbox widget.

=cut

sub render_widget {
    my $self  = shift;
    my $field =  qq!<input type="hidden" name="@{[ $self->fallback_name ]}" id="@{[ $self->fallback_name ]}" value="0" />\n!;

    $field .= qq!<input!;
    $field .= qq! type="checkbox"!;
    $field .= qq! name="@{[ $self->input_name ]}"!;
    $field .= qq! id="@{[ $self->input_name ]}"!;
    $field .= qq! value="1"!;
    $field .= $self->_widget_class;
    $field .= qq! checked="checked"! if $self->current_value;

    $field .= $self->javascript;
    
    $field .= qq! />\n!;
    Jifty->web->mason->out($field);
    '';
}

1;
