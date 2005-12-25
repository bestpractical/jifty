use strict;
use warnings;

package Jifty::Callback::ComponentSource;
use base qw/Jifty::Callback/;

=head1 NAME

Jifty::Callback::ComponentSource - Callback that compiles and C<comp>s a L<HTML::Mason> component

=head2 call [KEY1 => VAL1, ...]

Uses C<< Jifty->framework->mason->interp->mason_component >> to turn the callable
into a component, and then calls C<comp> on C<< Jifty->framework->mason >> with that.
Returns the return value of C<comp>.

If the C<make_component> call dies, logs a message and returns undef.

=cut

sub call {
    my $self = shift;
    my %args = $self->call_arguments(@_);

    my $comp = eval { Jifty->framework->mason->interp->make_component( comp_source => $self->callable ); };
    my $err = $@;
    if ($err) {
        $self->log->fatal("Error compiling mason component for callback: ", $err);
        return;
    } 

    return Jifty->framework->mason->comp($comp, %args);
} 

1;
