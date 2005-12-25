use warnings;
use strict;
 
package Jifty::Web::Form::Field::Radio;

use base qw/Jifty::Web::Form::Field/;

=head2 render_widget

Renders the whole radio button collection.

=cut

sub render_widget {
    my $self  = shift;

    for my $opt (@{ $self->action->available_values($self->name) }) {
        $self->render_option($opt);
    }
}

=head2 render_option option

Renders a radio widget

=cut

sub render_option {
    my $self = shift;
    my $opt = shift;
    my $display = $opt->{'display'};
    my $value   = defined $opt->{'value'} ? $opt->{'value'} : '';

    my $id = $self->input_name . "-" . $value;
    $id =~ s/\s+/_/;
    my $field = qq! <input type="radio" !;
    $field .= qq! name="@{[ $self->input_name ]}"!;
    $field .= qq! id="@{[ $id ]}"!;
    $field .= qq! value="@{[ $value ]}"!;
    $field .= $self->_widget_class;

    $field .= qq! checked="1" !
      if defined $self->current_value and $self->current_value eq $value;
    $field .= qq!>$display\n!;
    Jifty->web->mason->out($field);
    '';
}

1;
