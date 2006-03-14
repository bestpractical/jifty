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

        push @$STACK,
            {
            id           => $halo_base,
            args         => [map {UNIVERSAL::isa($_,"GLOB") ? "*GLOB*" : $_} @{$context->args}],
            start_time   => Time::HiRes::time(),
            path         => $context->comp->path,
            subcomponent => (  $context->comp->is_subcomp() ? 1:0),
            name         => $context->comp->name,
            proscribed   => ($self->_unrendered_component($context) ? 1 :0 ),
            depth        => $DEPTH
            };

        push @$INDEX_STACK, $#{@$STACK};
    return if $self->_unrendered_component($context);

    $context->request->out('<span class="halo">');
}

=head2 end_component_hook CONTEXT_OBJECT

When we're done rendering a component, record how long it took
and close off the halo C<span> if we have one.


=cut

sub end_component_hook {
    my $self    = shift;
    my $context = shift;



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
    $context->request->out('</span>') unless ($frame->{'proscribed'});

}


=head2 render_halo_actions STACK_FRAME

When we're rendering the whole Mason component tree, this routine will
render our bits for just one stack frame.


=cut

sub render_halo_actions {
    my $self    = shift;
    my $stack_frame = shift;

    Jifty->web->mason->out( 
        qq{
<div class="halo_actions" id="halo-@{[$stack_frame->{'id'}]}-menu">
<span class="halo_name" onClick="toggle_display('halo-@{[$stack_frame->{'id'}]}-menu')">@{[$stack_frame->{'name'}]}</span>
<dl>
<dt>Path</dt>
<dd>@{[$stack_frame->{'path'}]}</dd>
<dt>Render time</dt>
<dd>@{[$stack_frame->{'render_time'}]}</dd>
<dt>});
# XXX TODO: we shouldn't be doing direct rendering of this if we can avoid it.
# but it would require a rework of how the render_xxx subs work in jifty core
Jifty->web->mason->out(Jifty->web->tangent( url =>"/=/edit/mason_component/".$stack_frame->{'path'}, label => 'Edit'));

Jifty->web->mason->out(qq{</dt>
<dt>Variables</dt>
<dd><textarea rows="5" cols="80">@{[YAML::Dump($stack_frame->{'args'})]}</textarea></dd>
<dt>SQL Statements</dt>
<dd><textarea rows="5" cols="80">@{[YAML::Dump($stack_frame->{'sql_statements'})]}</textarea></dd>
</dl>
</div>
})
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
    Jifty->web->mason->out(q{<div id="render_info" onClick="toggle_display('render_info_tree')">Page info</div>});
    Jifty->web->mason->out('<div id="render_info_tree">');
    Jifty->web->mason->out('<ul>');

    foreach my $item (@stack) {
        $item->{'render_time'} ||= int((Time::HiRes::time - $item->{'start_time'}) * 1000)/1000;
        if ( $item->{depth} > $depth ) {
            Jifty->web->mason->out("<ul>");
        } elsif ( $item->{depth} < $depth ) {
            Jifty->web->mason->out("</ul>\n") for ($item->{depth}+1 .. $depth);
        }

        Jifty->web->mason->out( "<li>");

        Jifty->web->mason->out(qq{<span class="halo_comp_info" } );
        Jifty->web->mason->out(qq{onClick="toggle_display('halo-}.$item->{id}.qq{-menu');"});
        Jifty->web->mason->out(qq{>}
                . $item->{'path'} . " - "
                . $item->{'render_time'}
                . qq{</span> }
        );

        Jifty->web->mason->out(Jifty->web->tangent( url =>"/=/edit/mason_component/".$item->{'path'}, label => 'Edit'))
          unless ($item->{subcomponent});
        $self->render_halo_actions($item);
        Jifty->web->mason->out( "</li>");
        $depth = $item->{'depth'};
    }

    Jifty->web->mason->out("</ul>\n") for (1 .. $depth);
    Jifty->web->mason->out('</div>');

}


1;
