use warnings;
use strict;
 
package Jifty::Web::Form::Field::Radio;

use base qw/Jifty::Web::Form::Field/;

=head1 NAME

Jifty::Web::Form::Field::Radio - Add a radio button to your forms

=head1 METHODS

=head2 render_widget

Renders the whole radio button collection.

=cut

sub render_widget {
    my $self  = shift;

    for my $opt ($self->available_values) {
        $self->render_option($opt);
    }
}

=head2 render_label

We need to output the label as a span instead since the labels are associated 
with the individual options.

=cut

sub render_label {
    my $self = shift;
    Jifty->web->out(
        qq!<span class="label @{[$self->classes]}">@{[_($self->label) ]}</span>\n!
    );

    return '';
}

=head2 render_option option

Renders a radio widget

=cut

sub render_option {
    my $self = shift;
    my $opt = shift;
    my $display = $opt->{'display'};
    my $value   = defined $opt->{'value'} ? $opt->{'value'} : '';

    
    my $id = $self->element_id . "-" . $value;
    $id =~ s/\s+/_/;
    my $field = qq! <input type="radio" !;
    $field .= qq! name="@{[ $self->input_name ]}"!;
    $field .= qq! id="@{[ $id ]}"!;
    $field .= qq! title="@{[ $self->title ]}"! if ($self->title);
    $field .= qq! value="@{[ $value ]}"!;
    $field .= $self->_widget_class;

    $field .= qq! checked="checked" !
      if defined $self->current_value and $self->current_value eq $value;
    $field .= $self->javascript;
    $field .= qq! /><label for="@{[ $id ]}"!;
    $field .= $self->_widget_class;
    $field .= qq!>$display</label>\n!;
    $field = qq{<span class="radiooption">$field</span>};

    Jifty->web->out($field);
    '';
}


1;
