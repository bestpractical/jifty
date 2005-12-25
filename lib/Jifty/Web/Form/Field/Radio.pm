use warnings;
use strict;
 
package Jifty::Web::Form::Field::Radio;

use base qw/Jifty::Web::Form::Field/;

=head2 render_widget

Renders the select widget.

=cut

sub render_widget {
    my $self  = shift;

    for my $opt (@{ $self->action->available_values($self->name) }) {
        $self->render_option($opt);
    }
}

=head2 render_option option

Renders one entry in a SELECT widget

=cut

sub render_option {
    my $self = shift;
    my $opt = shift;
        my $display = $opt->{'display'};
        my $value   = $opt->{'value'} ||'' ;
    my $field = qq! <input type="radio" !;
    $field .= qq! name="@{[ $self->input_name ]}"!;
    $field .= qq! id="@{[ $self->input_name ]}"!;
    $field .= qq! value="@{[ $value ]}"!;
    $field .= qq! class="@{[ $self->class ]}@{[ $self->ajax_validates ? ' ajaxvalidation' : '' ]}" !;

    $field .= qq! checked="1" !
      if defined $self->default_value and $self->default_value eq $value;
    $field .= qq!>$display\n!;
    Jifty->mason->out($field);
    '';
}

1;
