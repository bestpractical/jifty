use warnings;
use strict;
 
package Jifty::Web::Form::Field::Upload;

=head1 NAME

Jifty::Web::Form::Field::Upload - File upload field

=head1 DESCRIPTION

An input field that renders using C<< <input type="file" /> >>.  The
argument value that the action recieves from this field via
L<Jifty::Action/argument_value> will be a filehandle, which can be
read in the usual ways.

=cut

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
