use warnings;
use strict;
package Jifty::Plugin::Halo::Mason;
use base qw/HTML::Mason::Plugin/;
use Time::HiRes 'time';
use Class::Trigger;
use Jifty::Plugin::Halo;

=head1 NAME

Jifty::View::Mason::Halo - Class for drawing "halos" around page components

=head1 DESCRIPTION

=head2 start_component_hook CONTEXT_OBJECT

Whenever we start to render a component, check to see if we can draw a
halo around the component.

Either way, record halo metadata.

=cut

sub start_component_hook {
    my $self    = shift;
    my $context = shift;

    return if ($context->comp->path || '') eq "/__jifty/halo";
    return unless Jifty->handler->stash->{'in_body'};
    return if $context->comp->is_subcomp;

    my $frame = Jifty::Plugin::Halo->push_frame(
        args         => [map { eval { defined $_ and fileno( $_ ) }  ? "*GLOB*" : $_} @{$context->args}],
        path         => $context->comp->path || '',
        name         => $context->comp->name || '(Unnamed component)',
    );

    $context->request->out(Jifty::Plugin::Halo->halo_header($frame));
}

=head2 end_component_hook CONTEXT_OBJECT

When we're done rendering a component, record how long it took
and close off the halo C<span> if we have one.

=cut

sub end_component_hook {
    my $self    = shift;
    my $context = shift;

    return if ($context->comp->path || '') eq "/__jifty/halo";
    return unless Jifty->handler->stash->{'in_body'};
    return if $context->comp->is_subcomp;

    my $frame = Jifty::Plugin::Halo->pop_frame;
    $context->request->out(Jifty::Plugin::Halo->halo_footer($frame));
}

1;
