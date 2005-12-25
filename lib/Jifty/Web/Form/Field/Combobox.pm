use warnings;
use strict;
 
package Jifty::Web::Form::Field::Combobox;

use base qw/Jifty::Web::Form::Field/;

=head2 render_widget

Renders the select widget.

=cut

sub render_widget {
    my $self  = shift;

my $field = <<"EOF";
<nobr>
<span id="@{[ $self->input_name ]}_Container" class="combobox">
<input name="@{[ $self->fallback_name ]}" 
       id="@{[ $self->input_name ]}" 
      class="@{[ $self->class ]}@{[ $self->ajax_validates ? ' ajaxvalidation' : '' ]} combo-text" 
       value="@{[ $self->current_value ]}" 
       type="text" 
       size="30"
       autocomplete="off" /><span id="@{[ $self->input_name ]}_Button" class="combo-button"></span></span><span style="display: none"></span><select 
        name="@{[ $self->input_name ]}" 
        id="@{[ $self->input_name ]}_List" 
        class="@{[ $self->class ]} combo-list" 
        onchange="ComboBox_SimpleAttach(this, this.form['@{[ $self->input_name ]}']); " 
        >
<option style="display: none" value=""></option>
EOF


    for my $opt (@{ $self->action->available_values($self->name) }) {
        my $display = $opt->{'display'};
        my $value   = $opt->{'value'} ||'' ;
        # TODO XXX FIXME worry about escape value, display?
        $field .= qq!<option value="$value"!;
        $field .= qq! selected="selected"!
            if defined $self->current_value and $self->current_value eq $value;
        $field .= qq!>$display</option>\n!;
    } 
    


$field .= <<"EOF";
</select>
<script language="javascript"><!--
ComboBox_InitWith('@{[ $self->input_name ]}');
//--></script>
</nobr>
EOF



        Jifty->mason->out($field);
    '';
}

1;
