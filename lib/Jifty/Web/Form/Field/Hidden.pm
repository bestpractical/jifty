use warnings;
use strict;
 
package JFDI::Web::Form::Field::Hidden;

use base qw/JFDI::Web::Form::Field/;

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
1;
