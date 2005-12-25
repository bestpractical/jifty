use strict;
use warnings;

package JFDI::Callback::String;
use base qw/JFDI::Callback/;

=head1 NAME

JFDI::Callback::String - Callback that just returns a string

=head2 call [KEY1 => VAL1, ...]

Outputs the string and returns whatever C<< JFDI->framework->mason->out >>
returns.

=cut

sub call {
    my $self = shift;
    return JFDI->framework->mason->out($self->callable);
} 

1;
