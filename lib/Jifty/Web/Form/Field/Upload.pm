use warnings;
use strict;
 
package Jifty::Web::Form::Field::Upload;

use base qw/Jifty::Web::Form::Field/;

=head2 render_widget

Renders the file upload widget.

=cut

sub render_widget {
    my $self  = shift;
    my $field = qq!<input type="file" name="@{[ $self->input_name ]}" />!;
    Jifty->mason->out($field);
    '';
}

1;
