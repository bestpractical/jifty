use warnings;
use strict;
 
package JFDI::Web::Form::Field::Unrendered;

use base qw/JFDI::Web::Form::Field/;

=head2 render

Don't render anything. For one reason or another, this form field should never, ever be rendered, perhaps
because it's internally generated and handled. 

=cut

sub render {
    my $self  = shift;
    # XXX TODO this shouldn't be in the superclass like that
    '';
}

1;
