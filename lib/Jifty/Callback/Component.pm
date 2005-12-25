use strict;
use warnings;

package Jifty::Callback::Component;
use base qw/Jifty::Callback/;

=head1 NAME

Jifty::Callback::Component - Callback that C<comp>s a L<HTML::Mason> component

=head2 call [KEY1 => VAL1, ...]

Calls C<comp> on C<< Jifty->framework->mason >> with the callable as the component.
This can be either a component path or a L<HTML::Mason::Component> object.
Returns the return value of C<comp>.

=cut

sub call {
    my $self = shift;
    my %args = $self->call_arguments(@_);
    return Jifty->framework->mason->comp($self->callable, %args);
} 

1;
