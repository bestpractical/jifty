use strict;
use warnings;

package Jifty::Callback::String;
use base qw/Jifty::Callback/;

=head1 NAME

Jifty::Callback::String - Callback that just returns a string

=head2 call [KEY1 => VAL1, ...]

Outputs the string and returns whatever C<< Jifty->framework->mason->out >>
returns.

=cut

sub call {
    my $self = shift;
    return Jifty->framework->mason->out($self->callable);
} 

1;
