use warnings;
use strict;
 
package Jifty::Web::Form::Field::Hidden;

use base qw/Jifty::Web::Form::Field/;

=head1 NAME

Jifty::Web::Form::Field::Hidden - Add hidden fields to your forms

=head1 METHODS

=head2 type

The HTML input type is C<hidden>.

=cut

sub type { 'hidden' }

=head2 render

Renders a hidden form field. Doesn't render anything except the widget itself.

=cut

sub render {
    my $self  = shift;
    $self->render_widget();
    return '';
}

=head2 handler_allowed HANDLER_NAME

Handlers are not useful on hidden elements

=cut

sub handler_allowed {
    undef;
}


1;
