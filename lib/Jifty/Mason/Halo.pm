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

    my $DEPTH = $context->request->notes('_halo_depth') || 0;
    my $STACK = $context->request->notes('_halo_stack')
        || $context->request->notes( '_halo_stack' => [] );
    my $INDEX_STACK = $context->request->notes('_halo_index_stack')
        || $context->request->notes( '_halo_index_stack' => [] );
    my $halo_base = Jifty->web->serial;

    $context->request->notes('_halo_depth' => ++$DEPTH);
    if ($STACK->[-1]) {
        push @{$STACK->[-1]->{sql_statements}}, Jifty->handle->sql_statement_log;
        Jifty->handle->clear_sql_statement_log;
    }

    push @$STACK, {
        id           => $halo_base,
        args         => [map { eval { fileno( $_ ) }  ? "*GLOB*" : $_} @{$context->args}],
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

    return if $context->comp->path eq "/__jifty/halo";

    my $STACK = $context->request->notes('_halo_stack');
    my $INDEX_STACK = $context->request->notes('_halo_index_stack');
    my $DEPTH = $context->request->notes('_halo_depth');

    my $FRAME_ID = pop @$INDEX_STACK;

    my $frame = $STACK->[$FRAME_ID];
    $frame->{'render_time'} = int((Time::HiRes::time - $frame->{'start_time'}) * 1000)/1000;


    push @{$frame->{sql_statements}}, Jifty->handle->sql_statement_log;
    Jifty->handle->clear_sql_statement_log;


    $context->request->notes('_halo_depth' => $DEPTH-1 );

    # If 
    return if $self->_unrendered_component($context);

    # print out the div with our halo magic actions.
    # if we didn't render a beginning of the span, don't render an end
    $context->request->out('</div>') unless ($frame->{'proscribed'});

}


=head2 render_halo_actions STACK_FRAME

When we're rendering the whole Mason component tree, this routine will
render our bits for just one stack frame.


=cut

sub render_halo_actions {
    my $self    = shift;
    my $stack_frame = shift;

    Jifty->web->mason->comp("/__jifty/halo", frame => $stack_frame);
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
        or not $context->request->notes('in_body'))
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
    my @stack = @{ Jifty->web->mason->notes('_halo_stack') };

    my $depth = 1;
    Jifty->web->mason->out(q{<a href="#" id="render_info" onClick="Element.toggle('render_info_tree'); return false">Page info</a>});
    Jifty->web->mason->out('<div style="display: none" id="render_info_tree">');
    Jifty->web->mason->out('<ul>');

    foreach my $item (@stack) {
        $item->{'render_time'} ||= int((Time::HiRes::time - $item->{'start_time'}) * 1000)/1000;
        if ( $item->{depth} > $depth ) {
            Jifty->web->mason->out("<ul>");
        } elsif ( $item->{depth} < $depth ) {
            Jifty->web->mason->out("</ul>\n") for ($item->{depth}+1 .. $depth);
        }

        Jifty->web->mason->out( "<li>");

        Jifty->web->mason->out(qq{<a href="#" class="halo_comp_info" } );
        my $id = $item->{id};
        Jifty->web->mason->out(qq|onMouseOver="halo_over('@{[$id]}')" |); 
        Jifty->web->mason->out(qq|onMouseOut="halo_out('@{[$id]}')" |); 
        Jifty->web->mason->out(qq|onClick="halo_toggle('$id'); return false;">|);
        Jifty->web->mason->out(
                  $item->{'path'} . " - "
                . $item->{'render_time'}
                . qq{</a> }
        );

        Jifty->web->mason->out(Jifty->web->tangent( url =>"/=/edit/mason_component/".$item->{'path'}, label => 'Edit'))
          unless ($item->{subcomponent});
        Jifty->web->mason->out( "</li>");
        $depth = $item->{'depth'};
    }

    Jifty->web->mason->out("</ul>\n") for (1 .. $depth);
    Jifty->web->mason->out('</div>');

    foreach my $item (@stack) {
        $self->render_halo_actions($item);
    }
}


1;
