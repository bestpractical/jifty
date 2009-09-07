use warnings;
use strict;
 
package Jifty::Web::Form::Field::Checkboxes;

use base qw/Jifty::Web::Form::Field/;

=head1 NAME

Jifty::Web::Form::Field::Checkboxes - Add a list of checkboxes for
multiple-choice selection

=head1 METHODS

=head2 render_widget

Renders the whole checkbox collection.

=cut

sub render_widget {
    my $self  = shift;
    $self->_render_checkboxes(0);
}


=head2 render_value

Renders the whole checkbox collection in disabled mode.

=cut

sub render_value {
    my $self  = shift;
    $self->_render_checkboxes(1);
}



sub _render_checkboxes {
    my $self  = shift;
    my $readonly = shift;

    my %checked;
    
    my $current_value = $self->current_value;
    if( defined($current_value) ) {        
        if( ref($current_value) eq 'ARRAY' ) {
            for my $value (@$current_value) {
                if( ref($value) eq 'HASH' ) {
                    $value = $value->{'value'};
                }
                $checked{$value} = 1;
            }
        }
    }
                
    Jifty->web->out('<ul class="checkboxlist">');
    
    for my $opt ($self->available_values) {
     
        my $display = ref($opt) ? $opt->{'display'} : $opt;
        my $value   = ref($opt) ? $opt->{'value'} : $opt;
        $value = '' if !defined($value);

        my $id = $self->element_id . "-" . $value;
        $id =~ s/\s+/_/;
        my $field = qq! <li class="checkboxlistitem"> !;
        $field .= qq! <input type="checkbox" !;
        $field .= qq! name="@{[ $self->input_name ]}"!;
        $field .= qq! id="@{[ $id ]}"!;
        $field .= qq! title="@{[ $self->title ]}"! if ($self->title);
        $field .= qq! value="@{[ $value ]}"!;
        $field .= $self->_widget_class;
        
        $field .= qq! checked="checked"! if $checked{$value};
        $field .= qq! disabled="disabled" readonly="readonly"! if $readonly;
        
        $field .= $self->javascript;
        $field .= qq! /><label for="@{[ $id ]}"!;
        $field .= $self->_widget_class;
        $field .= qq!>$display</label>\n!;
        $field = qq{<span class="checkboxlistitemlabel">$field</span></li>};
        
        Jifty->web->out($field);
    }
    Jifty->web->out('</ul>');
}




1;
