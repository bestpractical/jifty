package Jifty::Plugin::WikiToolbar::Textarea;
use base qw(Jifty::Web::Form::Field::Textarea);

sub rows { 30 };

sub render_widget {
    my $self  = shift;
    my $field;
    $field .= qq!<div id='toolbar'></div>!;
    $field .= qq!<textarea!;
    $field .= qq! name="@{[ $self->input_name ]}"!;
    $field .= qq! id="@{[ $self->element_id ]}"!;
    $field .= qq! rows="@{[$self->rows || 5 ]}"!;
    $field .= qq! cols="@{[$self->cols || 60]}"!;
    $field .= $self->_widget_class;
    $field .= qq! >!;
    $field .= Jifty->web->escape($self->current_value) if $self->current_value;
	$field .= qq!</textarea>\n!;
    Jifty->web->out($field);
    '';
}


1;
