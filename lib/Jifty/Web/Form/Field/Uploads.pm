use warnings;
use strict;
 
package Jifty::Web::Form::Field::Uploads;

=head1 NAME

Jifty::Web::Form::Field::Uploads - File uploads field

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
    my $field = qq!<div class="uploads">!;
    $field .= qq!<input type="file" name="@{[ $self->input_name ]}" !;
    $field .= $self->_widget_class();
    $field .= $self->javascript;
    $field .= qq!/>!;
    $field .= qq!<a href="#" class="attach-more">!;
    $field .= _('Attach another file');
    $field .= qq!</a></div>!;
    Jifty->web->out($field);
    '';
}


=head2 render_value

The 'value', rendered, is empty so that BLOBs and the like don't get
streamed to the browser.

=cut

sub render_value {
    '';
}

=head2 classes

Add 'upload' to the rest of the classes

=cut

sub classes {
    my $self = shift;
    return join(' ', 'upload', ($self->SUPER::classes));
}

1;
