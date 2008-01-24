use strict;
use warnings;

package Jifty::Plugin::Halo;
use base qw/Jifty::Plugin/;
use Time::HiRes 'time';
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
    return if $self->_pre_init;

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
    my ($self, $orig, $path, $args, $code) = @_;

    my $ID          = Jifty->web->serial;
    my $STACK       = Jifty->handler->stash->{'_halo_stack'} ||= [];
    my $DEPTH       = ++Jifty->handler->stash->{'_halo_depth'};

    # for now, call the last piece of the template's path the name
    $path =~ m{.*/(.+)};
    my $name = $1 || $path;

    my $deparsed = eval {
        require Data::Dump::Streamer;
        Data::Dump::Streamer::Dump($code)->Out;
    };

    my $frame = {
        id           => $ID,
        args         => [ %{ Jifty->web->request->arguments } ], # ugh :)
        start_time   => time,
        path         => $path,
        subcomponent => 0,
        name         => $name,
        proscribed   => 0,
        depth        => $DEPTH,
        perl         => $deparsed,
    };

    # if this is the first frame, discard anything from the previous queries
    my $previous = $STACK->[-1] || {};

    push @$STACK, $frame;
    my $STACK_INDEX = $#$STACK;

    $self->call_trigger('halo_pre_template', frame => $frame, previous => $previous);

    Template::Declare->buffer->append($self->halo_header($frame));
    $orig->();
    Template::Declare->buffer->append($self->halo_footer($frame));

    $frame->{'end_time'} = time;

    $self->call_trigger('halo_post_template', frame => $frame, previous => $previous);

    --Jifty->handler->stash->{'_halo_depth'};
}

sub halo_header {
    my $self  = shift;
    my $frame = shift;
    my $id    = $frame->{id};
    my $perl  = $frame->{perl} || '';
    my $name  = $frame->{name};

    for ($perl, $name) {
        $_ = Jifty->web->escape($_);
    }

    my $perl_link = $perl ? qq{ | <a id="halo-button-perl-$id" onclick="halo_perl('$id'); return false" href="#">P</a> } : '';
    my $perl_div = $perl ? qq{<div id="halo-perl-$id" class="halo_perl"><pre>$perl</pre></div>} : '';

    return << "    HEADER";
        <div id="halo-$id" class="halo">
            <div class="halo_header">
                <span class="halo_rendermode">
                    [
                    <a style="font-weight: bold"
                       id="halo-button-render-$id"
                       onclick="halo_render('$id'); return false"
                       href="#">R</a>
                    |
                    <a id="halo-button-source-$id"
                       onclick="halo_source('$id'); return false"
                       href="#">S</a>
                    $perl_link
                    ]
                </span>
                <div class="halo_name">$name</div>
            </div>
            $perl_div
            <div id="halo-inner-$id">
    HEADER
}

sub halo_footer {
    my $self  = shift;
    my $frame = shift;

    return << "    FOOTER";
            </div>
        </div>
    FOOTER
}


1;
