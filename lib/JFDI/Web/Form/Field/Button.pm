use warnings;
use strict;
 
package JFDI::Web::Form::Field::Button;

use base qw/JFDI::Web::Form::Field/;

=head2 render_widget

Renders the button widget.

=cut

sub render_widget {
    my $self  = shift;
    my $field = '<input type="submit" name="'
        . $self->input_name 
        . '" value="'
        . $self->label
        . '" onClick="jfdi_button_click();" '
        . ' />'."\n";
    JFDI->mason->out($field);
    return '';
}

1;
