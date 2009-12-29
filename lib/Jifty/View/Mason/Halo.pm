use warnings;
use strict;
package Jifty::View::Mason::Halo;
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

    my $frame = Jifty::Plugin::Halo->push_frame(
        args         => [map { eval { defined $_ and fileno( $_ ) }  ? "*GLOB*" : $_} @{$context->args}],
        path         => $context->comp->path || '',
        subcomponent => $context->comp->is_subcomp() ? 1 : 0,
        name         => $context->comp->name || '(Unnamed component)',
        proscribed   => $self->_unrendered_component($context) ? 1 : 0,
    );

    return if Jifty::Plugin::Halo->is_proscribed( $frame );

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

    my $frame = Jifty::Plugin::Halo->pop_frame;
    return if Jifty::Plugin::Halo->is_proscribed( $frame );
    $context->request->out(Jifty::Plugin::Halo->halo_footer($frame));
}

=head2 _unrendered_component CONTEXT

Returns true if we're not currently inside the "Body" section of the
webpage OR the current component is a subcomponent. (Rendering halos
for subcomponents being too "heavy")

=cut

sub _unrendered_component {
    my $self    = shift;
    my $context = shift;
    return $context->comp->is_subcomp ? 1 : 0; 
}

=head2 render_component_tree

Once we're just about to finish rendering our HTML page (just before
the C<</body>> tag, we should call render_component_tree to output all
the halo data and metadata.

=cut

sub render_component_tree {
    my $self  = shift;
    return if Jifty->config->framework('HideHalos');

    my @stack = @{ Jifty->handler->stash->{'_halo_stack'} };

    for (@stack) {
        $_->{'render_time'} = int((($_->{'end_time'}||time) - $_->{'start_time'}) * 1000)/1000
          unless defined $_->{'render_time'};
    }

    Jifty->web->mason->comp("/__jifty/halo", stack => \@stack );
}


1;
