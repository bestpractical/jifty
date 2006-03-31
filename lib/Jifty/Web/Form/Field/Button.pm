use warnings;
use strict;
 
package Jifty::Web::Form::Field::Button;

use base qw/Jifty::Web::Form::Field/;

=head2 render_widget

Renders the button widget.

=cut

sub render_widget {
    my $self  = shift;
    my $field = join(
        ' ',
        '<input',
        'type="submit"',
        'name="' . $self->input_name . '" ',
        'value="' . _($self->label ). '"',
        $self->_widget_class('button'),
        $self->javascript,
        ' />',
        "\n"
    );
    Jifty->web->out($field);
    return '';
}

1;
