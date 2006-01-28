use warnings;
use strict;
package Jifty::Mason::Halo;
use base qw/HTML::Mason::Plugin/;
use Time::HiRes ();


sub start_component_hook {
    my $self    = shift;
    my $context = shift;

    my $STACK = $context->request->notes('_halo_stack') || $context->request->notes('_halo_stack' => []);
    my $halo_base = Jifty->web->serial;
    if ($self->_proscribed_component($context)) {
    push @$STACK, { id => $halo_base, start_time => Time::HiRes::time(), proscribed => 1 };
    return;
    } else {
    push @$STACK, { id => $halo_base, start_time => Time::HiRes::time(), proscribed => 0 };
        }    


    $context->request->out('<span class="halo">');
    $context->request->out(qq{<span class="halo_button" id="halo-@{[$halo_base]}" onClick="halo_toggle(this)"><img src="/images/halo.png" alt="O"/></span>
});
}

sub end_component_hook {
    my $self    = shift;
    my $context = shift;

    my $STACK = $context->request->notes('_halo_stack');
    my $frame = pop @$STACK;
    return if $self->_proscribed_component($context);

    $self->render_halo_actions($context, $frame);
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
<span class="halo_path">@{[$comp->name]}</span>
<dl>
<dt>Render time</dt>
<dd>@{[int((Time::HiRes::time - $stack_frame->{'start_time'}) * 1000)/1000]}</dd>
<dt>});
# XXX TODO: we shouldn't be doing direct rendering of this if we can avoid it.
# but it would require a rework of how the render_xxx subs work in jifty core
$context->request->out(Jifty->web->tangent( url =>"/=/edit/mason_component/@{[$comp->path]}", label => 'Edit'));

$context->request->out(qq{</dt>
<dt>Variables</dt>
<dd>@{[YAML::Dump($args)]}</dd>

</dl>
</div>
})
}

sub _proscribed_component {
    my $self    = shift;
    my $context = shift;
    if (   $context->comp->is_subcomp()
        or $context->comp->name =~ /^(?:autohandler|dhandler)$/
        or not $context->request->notes('in_body'))
    {
        return 1;
    } else {
        return undef;
    }

}
1;
