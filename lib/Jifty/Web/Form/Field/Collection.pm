use warnings;
use strict;
 
package Jifty::Web::Form::Field::Collection;

use base qw/Jifty::Web::Form::Field/;

=head1 NAME

Jifty::Web::Form::Field::Collection - render a whole collection of available values

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
        qq!<span class="label @{[$self->classes]}">@{[_($self->label) ]}</span>\n!
    );

    return '';
}

=head2 render_option option

Renders a normal input field.

=cut

sub render_option {
    my $self = shift;
    my $opt = shift;
    my $display = $opt->{'display'};
    my $value   = defined $opt->{'value'} ? $opt->{'value'} : "0";

    my $id = $self->element_id . "-" . $value;
    $id =~ s/\s+/_/;
    my $field = qq! <input type="text" !;
    $field .= qq! name="@{[ $self->input_name ]}"!;
    $field .= qq! title="@{[ $self->title ]}"! if ($self->title);
    $field .= qq! id="@{[ $id ]}"!;
    $field .= qq! value="0"!;
    $field .= $self->_widget_class;

    $field .= qq{ /><label for="@{[ $id ]}"};
    $field .= $self->_widget_class;
    $field .= qq{ >$display</label>\n };

    $field = qq{<span class="multitext">$field</span>};

    Jifty->web->out($field);
    '';
}

1;
