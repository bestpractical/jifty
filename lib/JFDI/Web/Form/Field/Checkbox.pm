use warnings;
use strict;
 
package JFDI::Web::Form::Field::Checkbox;

use base qw/JFDI::Web::Form::Field/;

=head2 render_widget

Renders the checkbox widget.

=cut

sub render_widget {
    my $self  = shift;
    my $field =  qq!<input type="hidden" name="@{[ $self->fallback_name ]}" value="0" />\n!;
    $field .= qq!<input type="checkbox" name="@{[ $self->input_name ]}" value="1" !;
    $field .= qq! checked="checked" ! if $self->default_value;
    $field .= qq! />\n!;
    JFDI->mason->out($field);
    '';
}

1;
