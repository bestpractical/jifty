use warnings;
use strict;
 
package Jifty::Web::Form::Field::Select;

use base qw/Jifty::Web::Form::Field/;

=head1 NAME

Jifty::Web::Form::Field::Select - Add a list/popup menu control to your forms

=head1 METHODS

=head2 render_widget

Renders the select widget.

=cut

sub _render_select_begin {
    my $self  = shift;
    my $rendered = qq! <select !;
    $rendered .= qq! name="@{[ $self->input_name ]}"!;
    $rendered .= qq! id="@{[ $self->element_id ]}"!;
    $rendered .= qq! title="@{[ $self->title ]}"! if ($self->title);
    $rendered .= $self->_widget_class;
    $rendered .= $self->javascript;
    $rendered .= q! multiple="multiple"! if $self->multiple;
    $rendered .= qq!      >\n!;
    return $rendered;
}

sub _render_select_values {
    my $self = shift;
    my $rendered = '';

    my $current_value = $self->current_value;
    for my $opt ($self->available_values) {
        my $display = ref($opt) ? $opt->{'display'} : $opt;
        my $value   = ref($opt) ? $opt->{'value'} : $opt;
        $value = "" unless defined $value;
        $rendered .= qq!<option value="@{[ Jifty->web->escape($value) ]}"!;
        $rendered .= qq! selected="selected"!
          if defined $current_value
              && (
                  ref $current_value eq 'ARRAY'
                  ? ( grep { $value eq $_ } @$current_value )
                  : $current_value eq $value );
        $rendered .= qq!>!;
        $rendered .= Jifty->web->escape(_($display)) if defined $display;
        $rendered .= qq!</option>\n!;
    }

    return $rendered;
}

sub _render_select_end {
    my $self  = shift;
    return qq!</select>\n!;
}

sub render_widget {
    my $self = shift;

    my $field = $self->_render_select_begin;
    $field .= $self->_render_select_values;
    $field .= $self->_render_select_end;

    Jifty->web->out($field);
    '';
}

=head2 render_value

Rather than rendering the "key" side of our value for this field, render
what would actually display to the user in the select-box

=cut


sub render_value {
    my $self  = shift;
    my $field = '<span';
    $field .= qq! class="@{[ $self->classes ]}"> !;
    my $value = $self->current_value;
    if(defined $value) {
        my @value = grep { $_->{value} eq $value } $self->available_values;
        $value = $value[0]->{display} if scalar @value;
    }
    $field .= Jifty->web->escape(_($value)) if defined $value;
    $field .= qq!</span>\n!;
    Jifty->web->out($field);
    return '';
}

1;
