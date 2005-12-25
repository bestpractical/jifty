use warnings;
use strict;
 
package Jifty::Web::Form::Field::Button;

use base qw/Jifty::Web::Form::Field/;

=head2 render_widget

Renders the button widget.

=cut

sub render_widget {
    my $self  = shift;
    my $field = '<input type="'.$self->type
        . '" name="'
        . $self->input_name 
        . '" value="'
        . $self->label
        . '"'
        . $self->javascript
        . ' />'."\n";
    Jifty->mason->out($field);
    return '';
}

1;
