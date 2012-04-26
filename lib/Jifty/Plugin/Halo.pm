use strict;
use warnings;

package Jifty::Plugin::Halo;
use Jifty::Plugin::Halo::Mason;
use base qw/Jifty::Plugin/;
use Time::HiRes 'time';
use Class::Trigger;

=head1 NAME

Jifty::Plugin::Halo - Provides halos

=head1 DESCRIPTION

This plugin provides L<http://seaside.st|Seaside>-esque halos for your
application. It's included by default when using Jifty with DevelMode
turned on.

=cut

=head2 init

Only enable halos in DevelMode. Add our instrumentation to
L<Template::Declare>.

=cut

sub init {
    my $self = shift;
    return if $self->_pre_init;
    return unless Jifty->config->framework('DevelMode');

    Jifty->web->add_javascript( 'halo.js' );
    Jifty->web->add_css( 'halo.css' );

    warn "Overwriting an existing Template::Declare->around_template"
        if Template::Declare->around_template;
    Template::Declare->around_template(sub { $self->around_template(@_) });

    push @{ Jifty->config->framework('Web')->{'MasonConfig'}{plugins} },
        'Jifty::Plugin::Halo::Mason';
    Jifty::View->add_trigger( body_start => sub { $self->body_start } );
    Jifty::View->add_trigger( body_end => sub { $self->body_end } );

    Jifty->add_trigger( post_init => sub { $self->find_halo_plugins } );
}

=head2 find_halo_plugins

Finds plugins which have C<halo_pre_template> or C<halo_post_template>
methods, and adds them as callbacks in the requisite places.

=cut

sub find_halo_plugins {
    my $self = shift;
    for my $plugin (Jifty->plugins) {
        for my $cb (grep {$plugin->can($_)} qw/ halo_pre_template halo_post_template/ ) {
            Jifty::Plugin::Halo->add_trigger(
                $cb => sub { $plugin->$cb(@_) },
            );
        }
    }
}

=head2 around_template

This is called to instrument L<Template::Declare> templates. We also draw a halo
around the template itself.

=cut

sub around_template {
    my ($self, $orig, $path, $args, $code) = @_;

    return $orig->() if $path eq "/__jifty/halo";
    return $orig->() unless Jifty->handler->stash->{'in_body'};

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

=head2 halo_header frame -> string

This will give you the halo header which includes links to the various
information displays for this template.

=cut

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

=head2 halo_footer frame -> string

This will give you the halo footer which includes the actual information to
be displayed when the user pokes the halo.

=cut

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

=head2 new_frame -> hashref

Gives you a new frame for storing halo information.

=cut

sub new_frame {
    my $self = shift;

    my $args = {
        name => "arguments",
        callback => sub {
            my $frame = shift;
            my @out;

            my @args;
            while (my ($key, $value) = splice(@{$frame->{args}},0,2)) {
                push @args, [$key, $value];
            }

            for (sort { $a->[0] cmp $b->[0] } @args) {
                my ($name, $value) = @$_;
                my $ref = ref($value);
                my $out = qq{<b>$name</b>: };

                if ($ref) {
                    my $expanded = Jifty->web->serial;
                    my $yaml =
                      eval { defined $value && fileno($value) }
                      ? '*GLOB*' : Jifty->web->escape( Jifty::YAML::Dump($value) );

                    $out .= qq{<a href="#" onclick="jQuery(Jifty.\$('$expanded')).toggle(); return false">$ref</a><div id="$expanded" class="halo-argument" style="display: none"><pre>$yaml</pre></div>};
                }
                elsif (defined $value) {
                    $out .= Jifty->web->escape($value);
                }
                else {
                    $out .= "undef";
                }

                push @out, $out;
            }

            return undef if @out == 0;

            return "<ul>"
                 . join("\n",
                        map { "<li>$_</li>" }
                        @out)
                 . "</ul>";
        },
    };

    return {
        id           => Jifty->web->serial,
        start_time   => time,
        subcomponent => 0,
        displays     => {
            R => { name => "render", default => 1 },
            S => { name => "source" },
            A => $args,
        },
        @_,
    };
}

=head2 push_frame -> frame

Creates and pushes a frame onto the render stack. Mason's halos do not support
I<arounding> a component, so we fake it with an explicit stack.

This also triggers C<halo_pre_template> for plugins adding halo data.

=cut

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

=head2 pop_frame -> frame

Pops a frame off the render stack. Mason's halos do not support
C<arounding> a component, so we fake it with an explicit stack.

This also triggers C<halo_post_template> for plugins adding halo data.

=cut

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

sub body_start {
    my $self = shift;
    Jifty->handler->stash->{'in_body'} = 1;
}

sub body_end {
    my $self = shift;
    Jifty->handler->stash->{'in_body'} = 0;
    $self->render_component_tree;
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
        $_->{'render_time'} = int((($_->{'end_time'}||time) - $_->{'start_time'}) * 1000)/1000
          unless defined $_->{'render_time'};
    }
    Jifty->web->render_template("/__jifty/halo", {stack => \@stack} );
    return 1;
}

1;
