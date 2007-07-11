use warnings;
use strict;
 
package Jifty::Plugin::Userpic::Widget;

use base qw/Jifty::Web::Form::Field/;

=head1 NAME

Jifty::Plugin::Userpic::Widget - google map widget for geolocation display and editing

=head1 METHODS


=cut

sub accessors { shift->SUPER::accessors() };

=head2 render_widget

Renders form fields as googlemap widget.

=cut

sub render_widget {
    my $self     = shift;
    my $readonly = shift;
    my $action   = $self->action;
    $readonly = $readonly ? 1 : 0;

    if ( $self->current_value ) {
        Jifty->web->out( qq{<img src="/=/plugin/userpic/}
                . $self->action->record_class . "/"
                . $action->record->id . '/'
                . $self->name
                . qq{">} );
    }
    unless ($readonly) {
        my $field = qq!<input type="file" name="@{[ $self->input_name ]}" !;
        $field .= $self->_widget_class();
        $field .= qq!/>!;
        Jifty->web->out($field);
    }
    '';
}


=head2 render_value

Renders value as a checkbox widget.

=cut

sub render_value {
    $_[0]->render_widget('readonly');
    return '';
}

1;
