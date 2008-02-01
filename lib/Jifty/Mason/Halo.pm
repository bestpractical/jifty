use warnings;
use strict;
package Jifty::Mason::Halo;
use base qw/HTML::Mason::Plugin/;
use Time::HiRes 'time';
use Class::Trigger;
use Jifty::Plugin::Halo;

=head1 NAME

Jifty::Mason::Halo - Class for drawing "halos" around page components

=head1 DESCRIPTION


=cut


=head2 start_component_hook CONTEXT_OBJECT

Whenever we start to render a component, check to see if we can draw a halo around the component.

Either way, record halo metadata.

=cut


sub start_component_hook {
    my $self    = shift;
    my $context = shift;

    return if ($context->comp->path || '') eq "/__jifty/halo";

    my $STACK       = Jifty->handler->stash->{'_halo_stack'} ||= [];
    my $INDEX_STACK = Jifty->handler->stash->{'_halo_index_stack'} ||= [];
    my $DEPTH       = ++Jifty->handler->stash->{'_halo_depth'};

    my $frame = Jifty::Plugin::Halo->new_frame(
        args         => [map { eval { defined $_ and fileno( $_ ) }  ? "*GLOB*" : $_} @{$context->args}],
        path         => $context->comp->path || '',
        subcomponent => $context->comp->is_subcomp() ? 1 : 0,
        name         => $context->comp->name || '(Unnamed component)',
        proscribed   => $self->_unrendered_component($context) ? 1 : 0,
        depth        => $DEPTH,
    );

    my $previous = $STACK->[-1];
    push @$STACK, $frame;
    push @$INDEX_STACK, $#$STACK;

    return if $self->_unrendered_component($context);

    $self->call_trigger('halo_pre_template', frame => $frame, previous => $previous);

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

    my $STACK       = Jifty->handler->stash->{'_halo_stack'};
    my $INDEX_STACK = Jifty->handler->stash->{'_halo_index_stack'};
    my $FRAME_ID    = pop @$INDEX_STACK;

    my $frame = $STACK->[$FRAME_ID];
    $frame->{'end_time'} = time;

    my $previous = $FRAME_ID ? $STACK->[$FRAME_ID - 1] : {};

    $self->call_trigger('halo_post_template', frame => $frame, previous => $previous);

    --Jifty->handler->stash->{'_halo_depth'};

    return if $self->_unrendered_component($context);

    # print out the div with our halo magic actions.
    # if we didn't render a beginning of the span, don't render an end
    unless ( $frame->{'proscribed'} ) {
        my $comp_name = $frame->{'path'};
        $context->request->out(Jifty::Plugin::Halo->halo_footer($frame));
    }
}

=head2 _unrendered_component CONTEXT

Returns true if we're not currently inside the "Body" section of the
webpage OR the current component is a subcomponent. (Rendering halos
for subcomponents being too "heavy")

=cut


sub _unrendered_component {
    my $self    = shift;
    my $context = shift;
    if (   $context->comp->is_subcomp()
        or not Jifty->handler->stash->{'in_body'})
    {
        return 1;
    } else {
        return undef;
    }

}

=head2 render_component_tree

Once we're just about to finish rendering our HTML page (just before
the C<</body>> tag, we should call render_component_tree to output all
the halo data and metadata.


=cut

sub render_component_tree {
    my $self  = shift;
    my @stack = @{ Jifty->handler->stash->{'_halo_stack'} };

    for (@stack) {
        $_->{'render_time'} = int((($_->{'end_time'}||time) - $_->{'start_time'}) * 1000)/1000
          unless defined $_->{'render_time'};
    }

    Jifty->web->mason->comp("/__jifty/halo", stack => \@stack );
}


1;
