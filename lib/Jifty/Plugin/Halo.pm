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

    # for now, call the last piece of the template's path the name
    $path =~ m{.*/(.+)};
    my $name = $1 || $path;

    my $frame = $self->push_frame(
        args  => [ %{ Jifty->web->request->arguments } ],
        path  => $path,
        name  => $name,
    );

    $frame->{displays}->{P} = {
        name     => "perl",
        callback => sub {
            my $deparsed = eval {
                require Data::Dump::Streamer;
                Data::Dump::Streamer::Dump($code)->Out;
            };
            Jifty->web->escape($deparsed);
        },
    };

    Template::Declare->buffer->append($self->halo_header($frame));
    $orig->();

    $frame = $self->pop_frame;
    Template::Declare->buffer->append($self->halo_footer($frame));
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
            qq{  onclick="halo_render('$id', '$name'); return false"},
            $d->{default} && qq{  style="font-weight:bold"},
            qq{  href="#">$letter</a>},
    }

    my $rendermode = '[ ' . join(' | ', @buttons) . ' ]';

    return << "    HEADER";
        <div id="halo-$id" class="halo">
            <div class="halo-header">
                <span id="halo-rendermode-$id" class="halo-rendermode">
                    $rendermode
                </span>
                <div class="halo-name">$name</div>
            </div>
            <div id="halo-inner-$id">
                <div id="halo-rendered-$id">
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

        if ($d->{callback}) {
            my $output =
                qq{<div id="halo-info-$name-$id" style="display: none">};

            if (defined(my $info = $d->{callback}->($frame))) {
                $output .= $info;
            }
            else {
                # downgrade the link to plaintext so it's obvious there's no
                # information available
                $output .= qq{<script type="text/javascript">remove_link('$id', '$name');</script>};
            }

            $output .= "</div>";
            push @divs, $output;
        }
    }

    my $divs = join "\n", @divs;

    return << "    FOOTER";
                </div>
                <div id="halo-info-$id">
                    $divs
                </div>
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

sub push_frame {
    my $self = shift;

    my $STACK       = Jifty->handler->stash->{'_halo_stack'} ||= [];
    my $DEPTH       = ++Jifty->handler->stash->{'_halo_depth'};
    my $INDEX_STACK = Jifty->handler->stash->{'_halo_index_stack'} ||= [];

    # if this is the first frame, discard anything from the previous queries
    my $previous = $STACK->[-1] || {};

    my $frame = $self->new_frame(@_, previous => $previous, depth => $DEPTH);

    push @$STACK, $frame;
    push @$INDEX_STACK, $#$STACK;

    $self->call_trigger('halo_pre_template', frame => $frame, previous => $previous);

    return $frame;
}

sub pop_frame {
    my $self = shift;

    my $STACK       = Jifty->handler->stash->{'_halo_stack'} ||= [];
    my $INDEX_STACK = Jifty->handler->stash->{'_halo_index_stack'} ||= [];
    my $FRAME_ID    = pop @$INDEX_STACK;

    my $frame = $STACK->[$FRAME_ID];
    my $previous = $frame->{previous};

    $frame->{'end_time'} = time;

    $self->call_trigger('halo_post_template', frame => $frame, previous => $previous);

    --Jifty->handler->stash->{'_halo_depth'};

    return $frame;
}

1;
