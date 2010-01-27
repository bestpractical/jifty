use warnings;
use strict;

package Jifty::Web::Form::Field::OrderedList;

use base qw/Jifty::Web::Form::Field/;
__PACKAGE__->mk_accessors('with_select');
sub accessors {
    shift->SUPER::accessors(),'with_select', 
}

=head1 NAME

Jifty::Web::Form::Field::OrderedList - Ordered list field

=head1 DESCRIPTION

Ordered list field, if with_select => 1, then select functionality will be
added to.

=head1 METHODS

=head2 render_widget

Renders the select widget.

=cut

sub render_widget {
    my $self = shift;

    my $current_value = $self->current_value;
    $current_value = [ $current_value ] unless ref $current_value eq 'ARRAY';

    my $unselected    = [];
    my %selected;

    for my $opt ( $self->available_values ) {
        my $display = ref($opt) ? $opt->{'display'} : $opt;
        my $value   = ref($opt) ? $opt->{'value'}   : $opt;
        if ( grep { $value eq $_ } @$current_value ) {
            $selected{$value} = $display;
        }
        else {
            push @$unselected, { display => $display, value => $value };
        }
    }

    my $field = qq!<div class="ordered-list-container">!;

    if ($self->with_select) {
        $field .= qq!<div class="unselected">!;
        $field .= qq!<ul class="unselected">!;
        $field .= qq!<li class="head">!;
        $field .= _('Unselected');
        $field .= qq!</li>!;

        for my $opt (@$unselected) {
            $field .= qq!<li>!;
            $field .= Jifty->web->escape( _( $opt->{display} ) );
            $field .=
qq!<input disabled="disabled" class="hidden value" value="@{[ Jifty->web->escape($opt->{value}) ]}"!;
            $field .= qq!</li>!;
        }
        $field .= qq!</ul></div>!;
    }

    $field .= qq!<div class="selected">!;
    $field .= qq!<ul class="selected">!;
    if ( $self->with_select ) {
        $field .= qq!<li class="head">!;
        $field .= _('Selected');
        $field .= qq!</li>!;
    }
    for my $value (@$current_value) {
        $field .= qq!<li>!;
        $field .= Jifty->web->escape( _( $selected{$value} ) );
        $field .= qq!<input disabled="disabled" class="hidden value" value="@{[ Jifty->web->escape($value) ]}"!;
        $field .= qq!</li>!;
    }
    $field .= qq!</ul></div>!;

    # the real submit one
    $field .= qq!<div class="hidden">!;
    $field .= qq!<select class="submit hidden" multiple="multiple"!;
    $field .= qq! name="@{[ $self->input_name ]}"!;
    $field .= qq! id="@{[ $self->element_id ]}"!;
    $field .= qq! >!;
    for my $value (@$current_value) {
        $field .= qq!<option value="@{[ Jifty->web->escape($value) ]}"!;
        $field .= qq!selected="selected" >!;
        $field .= Jifty->web->escape( _( $selected{$value} ) );
        $field .= qq!</option>\n!;
    }
    $field .= qq!</select></div>!;

    $field .= qq!</div>!;
    Jifty->web->out($field);
    '';
}

1;
