use strict;
use warnings;


package Jifty::Plugin::UUID::Widget;

use base qw/Jifty::Web::Form::Field/;

=head1 NAME

Jifty::Plugin::UUID::Widget -  Widget for UUID plugin

=head1 METHODS

=head2 render_widget

Renders form fields as a UUID.

=cut

sub render_widget {
    my $self     = shift;
    my $action   = $self->action;
    
    my $name = $self->name;
    if ( $action->record->$name() ) {
        Jifty->web->out(  $action->record->$name() );
    } else { 
        Jifty->web->out("<i>"._('No value yet')."</i>");

    }
    '';
}

=head1 SEE ALSO

L<Jifty::Plugin::UUID>, L<Jifty::Web::Form::Field>

=head1 AUTHOR

Jesse Vincent

=head1 LICENSE

Jifty is Copyright 2005-2007 Best Practical Solutions, LLC.
Jifty is distributed under the same terms as Perl itself.

=cut

1;
