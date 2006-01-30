use warnings;
use strict;
package Jifty::Mason::Halo;
use base qw/HTML::Mason::Plugin/;
use Time::HiRes ();


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



        push @$STACK,
            {
            id         => $halo_base,
            start_time => Time::HiRes::time(),
            path        => $context->comp->path,
            subcomponent => (  $context->comp->is_subcomp() ? 1:0),
            name        => $context->comp->name,
            proscribed => ($self->_unrendered_component($context) ? 1 :0 ),
            depth => $DEPTH
            };

        push @$INDEX_STACK, $#{@$STACK};
    return if $self->_unrendered_component($context);

    $context->request->out('<span class="halo">');
    $context->request->out(
        qq{<span class="halo_button" id="halo-@{[$halo_base]}" onClick="toggle_display('halo-@{[$halo_base]}-menu')"><img src="/images/halo.png" alt="O"/></span>
}
    );
}

sub end_component_hook {
    my $self    = shift;
    my $context = shift;



    my $STACK = $context->request->notes('_halo_stack');
    my $INDEX_STACK = $context->request->notes('_halo_index_stack');
    my $DEPTH = $context->request->notes('_halo_depth');

    my $FRAME_ID = pop @$INDEX_STACK;

    my $frame = $STACK->[$FRAME_ID];
    $frame->{'render_time'} = int((Time::HiRes::time - $frame->{'start_time'}) * 1000)/1000;
    $context->request->notes('_halo_depth' => $DEPTH-1 );

    # If 
    return if $self->_unrendered_component($context);

    # print out the div with our halo magic actions.
    $self->render_halo_actions($context, $frame);
    # if we didn't render a beginning of the span, don't render an end
    $context->request->out('</span>') unless ($frame->{'proscribed'});

}

sub render_halo_actions {
    my $self    = shift;
    my $context = shift;
    my $stack_frame = shift;
    my $comp    = $context->comp();
    my $args = $context->args;

    $context->request->out( 
        qq{
<div class="halo_actions" id="halo-@{[$stack_frame->{'id'}]}-menu">
<span class="halo_name">@{[$comp->name]}</span>
<dl>
<dt>Path</dt>
<dt>@{[$comp->path]}</dd>
<dt>Render time</dt>
<dd>@{[$stack_frame->{'render_time'}]}</dd>
<dt>});
# XXX TODO: we shouldn't be doing direct rendering of this if we can avoid it.
# but it would require a rework of how the render_xxx subs work in jifty core
$context->request->out(Jifty->web->tangent( url =>"/=/edit/mason_component/".$comp->path, label => 'Edit'));

$context->request->out(qq{</dt>
<dt>Variables</dt>
<dd>@{[YAML::Dump($args)]}</dd>

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

sub render_component_tree {
    my $self  = shift;
    my @stack = @{ Jifty->web->mason->notes('_halo_stack') };

    my $depth = 1;
    Jifty->web->mason->out(q{<div id="render_info" onClick="toggle_display('render_info_tree')">Page info</div>});
    Jifty->web->mason->out('<div id="render_info_tree">');
    Jifty->web->mason->out('<ul>');

    foreach my $item (@stack) {
        if ( $item->{depth} > $depth ) {
            Jifty->web->mason->out("<ul>");
        } elsif ( $item->{depth} < $depth ) {
            Jifty->web->mason->out("</ul>\n");
        }

        Jifty->web->mason->out( "<li>");

        Jifty->web->mason->out(qq{<span class="halo_comp_info"} );

        Jifty->web->mason->out(qq{onClick="toggle_display('halo-}.$item->{id}.qq{-menu');"});
        Jifty->web->mason->out(qq{>}
                . $item->{'path'} . " - "
                . $item->{'render_time'}
                . qq{</span>}
                );

    Jifty->web->mason->out(Jifty->web->tangent( url =>"/=/edit/mason_component/".$item->{'path'}, label => 'Edit'))
        unless ($item->{subcomponent});
    Jifty->web->mason->out( "</li>");
        $depth = $item->{'depth'};
    }

    Jifty->web->mason->out('</ul>');
    Jifty->web->mason->out('</div>');

}


1;
