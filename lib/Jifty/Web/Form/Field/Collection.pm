use warnings;
use strict;
 
package Jifty::Web::Form::Field::Collection;

use base qw/Jifty::Web::Form::Field/;

=head1 NAME

Jifty::Web::Form::Field::Collection - render a whole collection of available values

=head1 DESCRIPTION

Renders multiple text inputs with the same name, available_values used as defaults.

=head1 METHODS

=head2 render_widget

Renders the whole collection of available values.

=cut

sub render_widget {
    my $self  = shift;

    for my $opt ($self->available_values) {
        $self->render_option($opt);
    }
}

=head2 render_label

Render a label for our own.  We need to output the label as a span
instead since the labels are associated with the individual options.

=cut

sub render_label {
    my $self = shift;
    Jifty->web->out(
        qq{<span class="label @{[$self->classes]}">}
        . Jifty->web->escape(_($self->label))
        . qq{</span>\n}
    );

    return '';
}

=head2 render_option option

Renders a normal input field.

=cut

sub render_option {
    my $self = shift;
    my $opt = shift;
    my $display = ref($opt) ? $opt->{'display'} : $opt;
    my $value   = ref($opt) ? $opt->{'value'}   : $opt;
    $value = "0" unless defined $value;

    my $id = $self->element_id . "-" . $value;
    $id =~ s/\s+/_/;

    my $wclass = $self->_widget_class;

    my $field = qq! <input type="text" !;
    $field .= qq! name="@{[ Jifty->web->escape( $self->input_name ) ]}"!;
    $field .= qq! title="@{[ Jifty->web->escape( $self->title ) ]}"! if ($self->title);
    $field .= qq! id="@{[ Jifty->web->escape( $id ) ]}"!;
    $field .= qq! value="@{[ Jifty->web->escape( $value ) ]}""!;
    $field .= $wclass;
    $field .= qq{ />};

    $field .= qq{<label for="@{[ Jifty->web->escape( $id ) ]}"};
    $field .= $wclass;
    $field .= qq{ >@{[ Jifty->web->escape( $display ) ]}</label>\n };

    $field = qq{<span class="multitext">$field</span>};

    Jifty->web->out($field);
    '';
}

1;
