use strict;
use warnings;

package JFDI::Callback::Code;
use base qw/JFDI::Callback/;

=head1 NAME

JFDI::Callback::Code - Callback that calls a subroutine

=head2 call [KEY1 => VAL1, ...]

Calls the subroutine and returns whatever it returns.  Probably,
your subroutine should call a mason output method, since that's what
all of the other callback types do.

=cut

sub call {
    my $self = shift;
    my %args = $self->call_arguments(@_);
    return $self->callable->( %args );
} 

1;
