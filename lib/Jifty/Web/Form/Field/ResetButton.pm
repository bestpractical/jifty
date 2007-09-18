use warnings;
use strict;
 
package Jifty::Web::Form::Field::ResetButton;

use base qw/Jifty::Web::Form::Field::InlineButton/;

=head1 NAME

Jifty::Web::Form::Field::ResetButton - Add a reset button to your forms

=head1 METHODS

=head2 render_widget

Renders the reset button widget

=cut

sub render_widget {
    my $self  = shift;
    my $field = join(
        ' ',
        '<input',
        'type="reset"',
        'name="' . $self->input_name . '" ',
        ($self->title ? 'title="'.$self->title.'" ' : ''),
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
