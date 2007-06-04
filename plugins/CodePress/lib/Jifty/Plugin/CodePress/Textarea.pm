package Jifty::Plugin::CodePress::Textarea;
use base qw(Jifty::Web::Form::Field::Textarea);

sub render_widget {
    my $self  = shift;
    my $field;
    $field .= qq!<textarea!;
    $field .= qq! name="@{[ $self->input_name ]}"!;
    $field .= qq! id="@{[ $self->element_id ]}"!;
    $field .= qq! rows="@{[$self->rows || 25]}"!;
    $field .= qq! cols="@{[$self->cols || 80]}"!;
    $field .= $self->_widget_class( 'codepress' );
    $field .= qq! >!;
    $field .= Jifty->web->escape($self->current_value) if $self->current_value;
    $field .= qq!</textarea>\n!;

    Jifty->web->out($field);
    '';
}


1;
