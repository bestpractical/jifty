use warnings;
use strict;
 
package Jifty::Web::Form::Field::ResetButton;

use base qw/Jifty::Web::Form::Field::InlineButton/;


=head2 render

Renders the reset button widget

=cut

sub render_widget {
    my $self  = shift;
    my $field = join(
        ' ',
        '<input',
        'type="reset"',
        'name="' . $self->input_name . '" ',
        'value="' . _($self->label ). '"',
        $self->_widget_class('button', 'reset'),
        $self->javascript,
        ' />',
        "\n"
    );
    Jifty->web->out($field);
    return '';
}


1;
