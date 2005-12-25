use warnings;
use strict;
 
package Jifty::Web::Form::Field::Upload;

use base qw/Jifty::Web::Form::Field/;

=head2 render_widget

Renders the file upload widget.

=cut

sub render_widget {
    my $self  = shift;
    my $field = qq!<input type="file" name="@{[ $self->input_name ]}" !;
    $field .= $self->_widget_class();
        $field .= qq!/>!;
    Jifty->web->out($field);
    '';
}

1;
