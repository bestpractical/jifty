use warnings;
use strict;
 
package Jifty::Web::Form::Field::Select;

use base qw/Jifty::Web::Form::Field/;

=head2 render_widget

Renders the select widget.

=cut

sub render_widget {
    my $self  = shift;
    my $field = qq! <select !;
    $field .= qq! name="@{[ $self->input_name ]}"!;
    $field .= qq! id="@{[ $self->input_name ]}"!;
    $field .= qq! class="@{[ $self->class ]}@{[ $self->ajax_validates ? ' ajaxvalidation' : '' ]}" !;
    $field .= qq!      >\n!;
    for my $opt (@{ $self->action->available_values($self->name) }) {
        my $display = $opt->{'display'};
        my $value   = $opt->{'value'} ||'' ;
        # TODO XXX FIXME worry about escape value, display?
        $field .= qq!<option value="$value"!;
        $field .= qq! selected="selected"!
            if defined $self->default_value and $self->default_value eq $value;
        $field .= qq!>$display</option>\n!;
    } 
    $field .= qq!</select>\n!;
    Jifty->mason->out($field);
    '';
}

1;
