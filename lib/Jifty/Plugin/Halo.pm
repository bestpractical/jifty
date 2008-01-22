use strict;
use warnings;

package Jifty::Plugin::Halo;
use base qw/Jifty::Plugin/;

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

sub post_init {
    Jifty->handle->log_sql_statements(1);
}

# parts of why this is.. weird is because we want to play nicely with Mason
# halos
sub around_template {
    my ($self, $orig, $path, $args) = @_;

    my $STACK       = Jifty->handler->stash->{'_halo_stack'} ||= [];
    my $DEPTH       = ++Jifty->handler->stash->{'_halo_depth'};
    my $ID          = Jifty->web->serial;

    # if we have queries at this point, they belong to the previous template
    if (@$STACK) {
        push @{$STACK->[-1]->{sql_statements}}, Jifty->handle->sql_statement_log;
        Jifty->handle->clear_sql_statement_log;
    }

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

    push @$STACK, $frame;
    my $STACK_INDEX = $#$STACK;

    Jifty->web->out(qq{<div id="halo-$ID">});
    $orig->();
    Jifty->web->out(qq{</div>});

    push @{$frame->{sql_statements}}, Jifty->handle->sql_statement_log;
    Jifty->handle->clear_sql_statement_log;

    --Jifty->handler->stash->{'_halo_depth'};
}

1;
