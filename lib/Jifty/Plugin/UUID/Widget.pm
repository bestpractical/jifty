use strict;
use warnings;


package Jifty::Plugin::UUID::Widget;

use base qw/Jifty::Web::Form::Field/;

=head1 NAME

Jifty::Plugin::UUID::Widget - 

=head1 METHODS


=cut

sub accessors { shift->SUPER::accessors() };

=head2 render_widget

Renders form fields as a uuid;

=cut

sub render_widget {
    warn "Rendering form field";
    my $self     = shift;
    my $action   = $self->action;
    my $readonly = 1;
    
        my $name = $self->name;
    if ( $action->record->$name() ) {
        Jifty->web->out(  $action->record->$name() );
    } else { 
        Jifty->web->out("<i>"._('No value yet')."</i>");

    }
    '';
}


1;
