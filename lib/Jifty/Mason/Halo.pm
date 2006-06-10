use warnings;
use strict;
package Jifty::Mason::Halo;
use base qw/HTML::Mason::Plugin/;
use Time::HiRes ();
Jifty->handle->log_sql_statements(1);

=head1 NAME

Jifty::Mason::Halo

=head1 DESCRIPTION


=cut


=head2 start_component_hook CONTEXT_OBJECT

Whenever we start to render a component, check to see if we can draw a halo around the component.

Either way, record halo metadata.

=cut


sub start_component_hook {
    my $self    = shift;
    my $context = shift;

    return if $context->comp->path eq "/__jifty/halo";

    Jifty->handler->stash->{ '_halo_index_stack' } ||= [];

    my $DEPTH = Jifty->handler->stash->{'_halo_depth'} || 0;
    my $STACK = Jifty->handler->stash->{'_halo_stack'} ||= [];
        
    my $INDEX_STACK = Jifty->handler->stash->{'_halo_index_stack'};

    my $halo_base = Jifty->web->serial;

    Jifty->handler->stash->{'_halo_depth'} = ++$DEPTH;
    if ($STACK->[-1]) {
        push @{$STACK->[-1]->{sql_statements}}, Jifty->handle->sql_statement_log;
        Jifty->handle->clear_sql_statement_log;
    }

    push @$STACK, {
        id           => $halo_base,
        args         => [map { eval { defined $_ and fileno( $_ ) }  ? "*GLOB*" : $_} @{$context->args}],
        start_time   => Time::HiRes::time(),
        path         => $context->comp->path,
        subcomponent => (  $context->comp->is_subcomp() ? 1:0),
        name         => $context->comp->name,
        proscribed   => ($self->_unrendered_component($context) ? 1 :0 ),
        depth        => $DEPTH
    };

    push @$INDEX_STACK, $#{@$STACK};
    return if $self->_unrendered_component($context);

    $context->request->out(qq{<div id="halo-@{[$halo_base]}">});
}

=head2 end_component_hook CONTEXT_OBJECT

When we're done rendering a component, record how long it took
and close off the halo C<span> if we have one.


=cut

sub end_component_hook {
    my $self    = shift;
    my $context = shift;

    return if $context->comp->path =~ "^/__jifty/halo";

    my $STACK = Jifty->handler->stash->{'_halo_stack'};
    my $INDEX_STACK = Jifty->handler->stash->{'_halo_index_stack'};
    my $DEPTH = Jifty->handler->stash->{'_halo_depth'};

    my $FRAME_ID = pop @$INDEX_STACK;

    my $frame = $STACK->[$FRAME_ID];
    $frame->{'render_time'} = int((Time::HiRes::time - $frame->{'start_time'}) * 1000)/1000;

    push @{$frame->{sql_statements}}, Jifty->handle->sql_statement_log;
    Jifty->handle->clear_sql_statement_log;


    Jifty->handler->stash->{'_halo_depth'} = $DEPTH-1 ;

    # If 
    return if $self->_unrendered_component($context);

    # print out the div with our halo magic actions.
    # if we didn't render a beginning of the span, don't render an end
    $context->request->out('</div>') unless ($frame->{'proscribed'});

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
        $_->{'render_time'} = int((Time::HiRes::time - $_->{'start_time'}) * 1000)/1000
          unless defined $_->{'render_time'};
    }

    Jifty->web->mason->comp("/__jifty/halo", stack => \@stack );
}


1;
