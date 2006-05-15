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
    $field .= qq! id="@{[ $self->element_id ]}"!;
    $field .= $self->_widget_class;
    $field .= qq!      >\n!;
    for my $opt (@{ $self->action->available_values($self->name) }) {
        my $display = $opt->{'display'};
        my $value   = $opt->{'value'};
        $value = "" unless defined $value;
        # TODO XXX FIXME worry about escape value, display?
        $field .= qq!<option value="$value"!;
        $field .= qq! selected="selected"!
            if defined $self->current_value and $self->current_value eq $value;
        $field .= qq!>$display</option>\n!;
    } 
    $field .= qq!</select>\n!;
    Jifty->web->out($field);
    '';
}

sub render_value {
    my $self  = shift;
    my $field = '<span';
    $field .= qq! class="@{[ $self->classes ]}"> !;
    my $value = $self->current_value;
    if(defined $value) {
        my @value = grep { $_->{value} eq $value }
                        @{ $self->action->available_values($self->name) };
        $value = $value[0]->{display} if scalar @value;
    }
    $field .= HTML::Entities::encode_entities(_($value)) if defined $value;
    $field .= qq!</span>\n!;
    Jifty->web->out($field);
    return '';
}

1;
