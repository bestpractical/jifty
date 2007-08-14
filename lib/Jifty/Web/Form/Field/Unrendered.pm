use warnings;
use strict;
 
package Jifty::Web::Form::Field::Unrendered;

use base qw/Jifty::Web::Form::Field/;

=head1 NAME

Jifty::Web::Form::Field::Unrendered - Handle unrendered fields

=head1 METHODS

=head2 render

Don't render anything. For one reason or another, this form field should never, ever be rendered, perhaps
because it's internally generated and handled. 

=cut

sub render {
    my $self  = shift;
    # XXX TODO this shouldn't be in the superclass like that
    '';
}


=head2 handler_allowed HANDLER_NAME

Returns 1 if the handler (e.g. onclick) is allowed.  Undef otherwise.

=cut

sub handler_allowed {
    undef;
}


1;
