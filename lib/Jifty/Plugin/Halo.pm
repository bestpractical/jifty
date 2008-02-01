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
    return unless Jifty->config->framework('DevelMode');

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

    my $STACK = Jifty->handler->stash->{'_halo_stack'} ||= [];
    my $DEPTH = ++Jifty->handler->stash->{'_halo_depth'};

    # for now, call the last piece of the template's path the name
    $path =~ m{.*/(.+)};
    my $name = $1 || $path;

    my $deparsed = eval {
        require Data::Dump::Streamer;
        Data::Dump::Streamer::Dump($code)->Out;
    };

    my $frame = $self->new_frame(
        args  => [ %{ Jifty->web->request->arguments } ], # ugh :)
        path  => $path,
        name  => $name,
        depth => $DEPTH,
        perl  => $deparsed,
    );

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
    my $self     = shift;
    my $frame    = shift;
    my $id       = $frame->{id};
    my $name     = Jifty->web->escape($frame->{name});
    my $displays = $frame->{displays};

    my @buttons;
    for my $letter (sort keys %$displays) {
        my $d = $displays->{$letter};
        my $name = Jifty->web->escape($d->{name});

        push @buttons, join "\n", grep { $_ }
            qq{<a id="halo-button-$name-$id"},
            qq{  onclick="halo_render('$id', '$name')"; return false"},
            $d->{default} && qq{  style="font-weight:bold"},
            qq{  href="#">$letter</a>},
    }

    my $rendermode = '[' . join('|', @buttons) . ']';

    return << "    HEADER";
        <div id="halo-$id" class="halo">
            <div class="halo-header">
                <span id="halo-rendermode-$id" class="halo-rendermode">
                    $rendermode
                </span>
                <div class="halo-name">$name</div>
            </div>
            <div id="halo-inner-$id">
    HEADER
}

sub halo_footer {
    my $self     = shift;
    my $frame    = shift;
    my $id       = $frame->{id};
    my $displays = $frame->{displays};

    my @divs;
    for (sort keys %$displays) {
        my $d = $displays->{$_};
        my $name = Jifty->web->escape($d->{name});

        push @divs, join "\n", grep { $_ }
            qq{<div id="halo-info-$name-$id" style="display: none">},
            $d->{callback} && $d->{callback}->($d),
            qq{</div>},
    }

    my $divs = join "\n", @divs;

    return << "    FOOTER";
            </div>
            <div id="halo-info-$id">
                $divs
            </div>
        </div>
    FOOTER
}

sub new_frame {
    my $self = shift;

    return {
        id           => Jifty->web->serial,
        start_time   => time,
        subcomponent => 0,
        proscribed   => 0,
        displays     => {
            R => { name => "render", default => 1 },
            S => { name => "source" },
        },
        @_,
    };
}

1;
