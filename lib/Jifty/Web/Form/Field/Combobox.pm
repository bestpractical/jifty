use warnings;
use strict;
 
package Jifty::Web::Form::Field::Combobox;

use base qw/Jifty::Web::Form::Field/;

=head1 NAME

Jifty::Web::Form::Field::Combobox - Add comboboxes to your forms

=head1 METHODS

=head2 render_widget

Renders the select widget.

=cut

sub render_widget {
    my $self  = shift;
    my $title = $self->title ? qq! title="@{[ $self->title ]}"!
                             : qq! !;

my $field = <<"EOF";
<nobr>
<span id="@{[ $self->element_id ]}_Container" class="combobox">
<input name="@{[ $self->fallback_name ]}" 
       id="@{[ $self->element_id ]}" 
       $title
       @{[ $self->_widget_class('combo-text')]}
       value="@{[ $self->current_value ]}" 
       type="text" 
       size="30"
       @{[ $self->javascript ]}
       autocomplete="off" /><span id="@{[ $self->element_id ]}_Button" 
       @{[ $self->_widget_class('combo-button')]}
        ></span></span><span style="display: none"></span><select 
        name="@{[ $self->input_name ]}" 
        id="@{[ $self->_element_id ]}_List" 
        @{[ $self->_widget_class('combo-list')]}
        onchange="ComboBox_SimpleAttach(this, this.form['@{[ $self->element_id ]}']); " 
        >
<option style="display: none" value=""></option>
EOF


    for my $opt ($self->available_values) {
        my $display = ref($opt) ? $opt->{'display'} : $opt;
        my $value   = (ref($opt) ? $opt->{'value'} : $opt) || '';

        # TODO XXX FIXME worry about escape value, display?
        $field .= qq!<option value="$value"!;
        $field .= qq! selected="selected"!
            if defined $self->current_value and $self->current_value eq $value;
        $field .= qq!>$display</option>\n!;
    } 
    


$field .= <<"EOF";
</select>
<script language="javascript">
ComboBox_InitWith('@{[ $self->element_id ]}');
</script>
</nobr>
EOF



        Jifty->web->out($field);
    '';
}


=head2 render_autocomplete

Never render anything for autocomplete.

=cut

sub render_autocomplete {''}

1;
