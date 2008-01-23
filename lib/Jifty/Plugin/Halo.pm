use strict;
use warnings;

package Jifty::Plugin::Halo;
use base qw/Jifty::Plugin/;
use Class::Trigger;

=head1 NAME

Jifty::Plugin::Halo

=head1 DESCRIPTION

This plugin provides L<http://seaside.st|Seasidesque> halos for
your application. It's included by default when using Jifty. (That's
a bug).

=cut

sub init {
    my $self = shift;

    # 0.28 added around_template instrumentation
    eval { Template::Declare->VERSION('0.28'); 1 }
        or do {
            Jifty->log->debug("Template::Declare 0.28 required for TD halos.");
            return;
        };

    warn "Overwriting an existing Template::Declare->around_template"
        if Template::Declare->around_template;

    Template::Declare->around_template(sub { $self->around_template(@_) });

}

# parts of why this is.. weird is because we want to play nicely with Mason
# halos
sub around_template {
    my ($self, $orig, $path, $args) = @_;

    my $STACK       = Jifty->handler->stash->{'_halo_stack'} ||= [];
    my $DEPTH       = ++Jifty->handler->stash->{'_halo_depth'};
    my $ID          = Jifty->web->serial;

    # for now, call the last piece of the template's path the name
    $path =~ m{.*/(.+)};
    my $name = $1 || $path;

    my $frame = {
        id           => $ID,
        args         => [ %{ Jifty->web->request->arguments } ], # ugh :)
        start_time   => Time::HiRes::time(),
        path         => $path,
        subcomponent => 0,
        name         => $name,
        proscribed   => 0,
        depth        => $DEPTH,
    };

    # if this is the first frame, discard anything from the previous queries
    my $previous = $STACK->[-1] || {};

    push @$STACK, $frame;
    my $STACK_INDEX = $#$STACK;

    $self->call_trigger('halo_pre_template', frame => $frame, previous => $previous);

    Jifty->web->out(qq{<div id="halo-$ID" class="halo">});
    $orig->();
    Jifty->web->out(qq{</div>});

    $self->call_trigger('halo_post_template', frame => $frame, previous => $previous);

    --Jifty->handler->stash->{'_halo_depth'};
}

1;
