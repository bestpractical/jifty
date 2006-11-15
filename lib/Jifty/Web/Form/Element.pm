use warnings;
use strict;

package Jifty::Web::Form::Element;

=head1 NAME

Jifty::Web::Form::Element - Some item that can be rendered in a form

=head1 DESCRIPTION

Describes any HTML element that might live in a form, and thus might
have javascript on it.

Handlers are placed on L<Jifty::Web::Form::Element> objects by calling
the name of the javascript event handler, such as C<onclick>, with a
set of arguments.

The format of the arguments passed to C<onclick> (or any similar
method) is a hash reference or string.  Strings are inserted verbatim.

Hash references can take a number of possible keys.  The most
important is the mode of the fragment replacement, if any; it is
specified by providing at most one of the following keys:

=over

=item append => PATH

Add the given C<PATH> as a new fragment, just before the close of the
CSS selector given by L</element>, which defaults to the end of the
current region.

=item prepend => PATH

Add the given C<PATH> as a new fragment, just after the start of the
CSS selector given by L</element>, which defaults to the start of the
current region.

=item replace_with => PATH

Replaces the region specified by the C<region> parameter (which
defaults to the current region) with the fragment located at the given
C<PATH>.  If C<undef> is passed as the C<PATH>, acts like a L</delete>.

=item refresh => REGION

Refreshes the given C<REGION>, which should be a
L<Jifty::Web::PageRegion> object, or the fully qualified name of such.

=item refresh_self => 1

Refreshes the current region; this is the default action, if a
non-empty C<args> is supplied, but no other mode is given.

=item delete => REGION

Removes the given C<REGION> from the page, permanently.

=back

The following options are also supported:

=over

=item toggle => BOOLEAN

If set to true, then the link will possibly toggle the region to
empty, if the region's current path is the same as the path the region
is trying to be set to.

=item region => REGION

The region that should be updated.  This defaults to the current
region.

=item element => CSS SELECTOR

A css selector specifying where the new region should be placed; used
with L</append> and L</prepend>, above.  The
L<Jifty::Web::PageRegion/get_element> method may be useful in
specifying elements of parent page regions.

=item submit => MONIKER

An action, moniker of an action, or array reference to such; these
actions are submitted when the event is fired.

=item disable => BOOLEAN

If true, disable all form fields associated with the actions in
C<submit> when this Element is clicked. This serves to give immediate
visual indication that the request is being processed, as well as to
prevent double-submits.

Defaults to true.

=item args => HASHREF

Arguments to the region.  These will override the arguments to the
region that the region was given when it was last rendered.

=item effect => STRING

The Prototype visual effect to use when updating or creating the
fragment.

=item effect_args => HASHREF

A hashref of arguments to pass to the effect when it is created.  These
can be used to change the duration of the effect, for instance.

=item confirm => STRING

Prompt the user with a Javascript confirm dialog with the given text
before carrying out the rest of the handlers. If the user cancels, do
nothing, otherwise proceed as normal.

TODO: This does not have a non-Javascript fallback method yet.

=back

=cut

use base qw/Jifty::Object Class::Accessor::Fast/;
use Jifty::JSON;

=head2 handlers

Currently, the only supported event handlers are C<onclick>.
WARNING: if you use the onclick handler, make sure that your javascript
is "return (function name);", or you may well get a very strange-looking
error from your browser.

=cut

sub handlers { qw(onclick); }

=head2 accessors

Any descendant of L<Jifty::Web::Form::Element> should be able to
accept any of the event handlers (above) as one of the keys to its
C<new> parameter hash.

=cut

sub accessors { shift->handlers, qw(class key_binding id label tooltip) }
__PACKAGE__->mk_accessors(qw(_onclick class key_binding id label tooltip));

=head2 new PARAMHASH OVERRIDE

Create a new C<Jifty::Web::Form::Element> object blessed with
PARAMHASH, and set with accessors for the hash values in OVERRIDE.

=cut

sub new {
    my ($class, $args, $override) = @_;
    # force using accessor for onclick init
    if (my $onclick = delete $args->{onclick}) {
        $override->{onclick} = $onclick;
    }

    my $self = $class->SUPER::new($args);

    if ($override) {
        for my $field ( $self->accessors() ) {
            # XXX: warn about unexpected ones
            $self->$field( $override->{$field} ) if exists $override->{$field};
        }
    }

    return $self;
}

=head2 onclick

=cut

sub onclick {
    my $self = shift;
    return $self->_onclick unless @_;

    my ($arg) = @_;

    $arg = [$arg] unless ref $arg eq 'ARRAY';

    #Normalize arguments as much as possible here, to simplify later
    #processing of them here and in Clickable.
    for my $hook ( @$arg ) {
        next unless ref $hook eq 'HASH';

        # Normalize actions to monikers to prevent circular references,
        # since Jifty::Action caches instances of Jifty::Web::Form::Clickable.
        if ( $hook->{submit} ) {
            $hook->{submit} = [ $hook->{submit} ] unless ref $hook->{submit} eq "ARRAY";
            $hook->{submit} = [ map { ref $_ ? $_->moniker : $_ } @{ $hook->{submit} } ];
        }

        if ( $hook->{args} ) {
            # We're going to pass complex query mapping structures
            # as-is to the server, but we need to make sure we're not
            # trying to pass around Actions, merely their monikers.
            for my $key ( keys %{ $hook->{args} } ) {
                next unless ref $hook->{args}{$key} eq "HASH";
                $hook->{args}{$key}{$_} = $hook->{args}{$key}{$_}->moniker
                  for grep { ref $hook->{args}{$key}{$_} }
                  keys %{ $hook->{args}{$key} };
            }
        } else {
            $hook->{args} = {};
        }

    }

    $self->_onclick($arg);
}

=head2 javascript

Returns the javascript necessary to make the events happen.

=cut

sub javascript {
    my $self = shift;

    my $response = "";
    for my $trigger ( $self->handlers ) {
        my $value = $self->$trigger;
        next unless $value;

        my @fragments;
        my %actions;    # Maps actions => disable?
        my $confirm;

        for my $hook (grep {ref $_ eq "HASH"} (@{$value})) {

            my %args;

            # Submit action
            if ( $hook->{submit} ) {
                my $disable = exists $hook->{disable} ? $hook->{disable} : 1;
                # Normalize to 1/0 to pass to JS
                $disable = $disable ? 1 : 0;
                $actions{$_} = $disable for (@{ $hook->{submit} }); 
            }

            $hook->{region} ||= Jifty->web->qualified_region;

            # Should we show a javascript confirm message?
            if ($hook->{confirm}) {
                $confirm = $hook->{confirm};
            }

            # Placement
            if (exists $hook->{append}) {
                @args{qw/mode path/} = ('Bottom', $hook->{append});
                $hook->{element} ||= "#region-".$hook->{region};
            } elsif (exists $hook->{prepend}) {
                @args{qw/mode path/} = ('Top', $hook->{prepend});
                $hook->{element} ||= "#region-".$hook->{region};
            } elsif (exists $hook->{replace_with}) {
                if (defined $hook->{replace_with}) {
                    @args{qw/mode path region/} = ('Replace', $hook->{replace_with}, $hook->{region});
                } else {
                    @args{qw/mode region/} = ('Delete', $hook->{region});
                }
            } elsif (exists $hook->{refresh}) {
                my $region = ref $hook->{refresh} ? $hook->{refresh} : Jifty->web->get_region($hook->{refresh});
                if ($region) {
                    @args{qw/mode path region/} = ('Replace', $region->path, $region->qualified_name);
                } else {
                    $self->log->debug("Can't find region ".$hook->{refresh});
                    @args{qw/mode path region/} = ('Replace', undef, $hook->{refresh});
                }
            } elsif ((exists $hook->{refresh_self} and Jifty->web->current_region) or (Jifty->web->current_region and $hook->{args} and %{$hook->{args}})) {
                # If we just pass arguments, treat as a refresh_self
                @args{qw/mode path region/} = ('Replace', Jifty->web->current_region->path, Jifty->web->current_region);
            } elsif (exists $hook->{delete}) {
                @args{qw/mode region/} = ('Delete', $hook->{delete});
            } else {
                # If we're not doing any of the above, skip this one
                next;
            }

            # Qualified name if we have a ref
            $args{region} = $args{region}->qualified_name if ref $args{region};

            # What element we're replacing.
            if ($hook->{element}) {
                $args{element} = ref $hook->{element} ? "#region-".$hook->{element}->qualified_name : $hook->{element};
                $args{region}  = $args{element} =~ /^#region-(\S+)/ ? "$1-".Jifty->web->serial : Jifty->web->serial;
            }

            # Arguments
            $args{args} = $hook->{args};

            # Toggle functionality
            $args{toggle} = 1 if $hook->{toggle};

            # Effects
            $args{$_} = $hook->{$_} for grep {exists $hook->{$_}} qw/effect effect_args/;

            push @fragments, \%args;
        }

        my $string = join ";", (grep {not ref $_} (ref $value eq "ARRAY" ? @{$value} : ($value)));
        if (@fragments or %actions) {

            my $update = "update( ". Jifty::JSON::objToJson( {actions => \%actions, fragments => \@fragments }, {singlequote => 1}) .", this );";
            $string .= $self->javascript_preempt ? "return $update" : "$update; return true;";
        }
        if ($confirm) {
            $string = "if(!confirm(" . Jifty::JSON::objToJson($confirm, {singlequote => 1}) . ")) return false;" . $string;
        }
        $response .= qq| $trigger="$string"|;
    }
    return $response;
}

=head2 javascript_preempt

Returns true if the the javascript's handlers should prevent the web
browser's standard effects from happening; that is, for C<onclick>, it
prevents buttons from submitting and the like.  The default is to
return true, but this can be overridden.

=cut

sub javascript_preempt { return 1 };

=head2 class

Sets the CSS class that the element will display as

=head2 key_binding

Sets the key binding associated with this elements

=head2 id

Subclasses must override this to provide each element with a unique id.

=head2 label

Sets the label of the element.  This will be used for the key binding
legend, at very least.

=head2 key_binding_javascript

Returns the javascript fragment to add key binding for this input, if
one exists.

=cut

sub key_binding_javascript {
    my $self = shift;
    my $key  = $self->key_binding;
    if ($key) {
        return "Jifty.KeyBindings.add(" . "'"
                . uc($key) . "', "
                . "'click', " . "'"
                . $self->id . "'," . "'"
                . $self->label . "'"
                . ");";
    }
}

=head2 render_key_binding

Renders the javascript from L</key_binding_javscript> in a <script>
tag, if needed.

=cut

sub render_key_binding {
    my $self = shift;
    return unless $self->key_binding;
    Jifty->web->out(
        '<script type="text/javascript"><!--' .
        "\n" .
        $self->key_binding_javascript .
        "\n" .
        "--></script>");
    return '';
}

1;
