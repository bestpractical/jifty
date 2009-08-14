use warnings;
use strict;

package Jifty::Web::Form::Element;
use Scalar::Util qw/blessed/;

=head1 NAME

Jifty::Web::Form::Element - Some item that can be rendered in a form

=head1 DESCRIPTION

Describes any HTML element that might live in a form, and thus might
have javascript on it.

Handlers are placed on L<Jifty::Web::Form::Element> objects by calling
the name of the javascript event handler, such as C<onclick> or C<onchange>, 
with a set of arguments.

The format of the arguments passed to C<onclick> (or any similar
method) is a string, a hash reference, or a reference to an array of
multiple hash references.  Strings are inserted verbatim.

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

A Jifty::Action, Jifty::Action moniker, hashref of 
    { action => Jifty::Action::Subclass, 
     arguments => { argument => value, argument2 => value2 }

or an arrayref of them.

These actions are submitted when the event is fired. Any arguments 
specified will override arguments submitted by form field.

If you explicitly pass C<undef>, then all actions will be submitted.
This can be useful in conjunction with an C<onclick> handler, since
declaring an C<onclick> handler inentionally turns off action submission.

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

The Scriptaculous or jQuery visual effect to use when updating or
creating the fragment.

=item effect_args => HASHREF

A hashref of arguments to pass to the effect when it is created.  These
can be used to change the duration of the effect, for instance.

=item remove_effect => STRING

As C<effect>, but for when the previous version of the region is
removed.

=item remove_effect_args => HASHREF

As C<effect_args>, but for C<remove_effect>.

=item beforeclick => STRING

String contains some Javascript code to be used before a click.

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

The following handlers are supported:

onclick onchange ondblclick onmousedown onmouseup onmouseover 
onmousemove onmouseout onfocus onblur onkeypress onkeydown 
onkeyup onselect

NOTE: onload, onunload, onsubmit and onreset are not yet supported

WARNING: if you use the onclick handler, make sure that your javascript
is "return (function name);", or you may well get a very strange-looking
error from your browser.

=cut

use constant handlers => qw(
    onclick onchange ondblclick onmousedown onmouseup onmouseover
    onmousemove onmouseout onfocus onblur onkeypress onkeydown
    onkeyup onselect
);

use constant possible_handlers => { map {($_ => 1)} handlers};


=head2 accessors

Any descendant of L<Jifty::Web::Form::Element> should be able to
accept any of the event handlers (above) as one of the keys to its
C<new> parameter hash.

=cut

sub accessors { handlers, qw(class title key_binding key_binding_label id label tooltip continuation rel) }

__PACKAGE__->mk_accessors(map "_$_", handlers);
__PACKAGE__->mk_accessors(qw(class title key_binding key_binding_label id label tooltip continuation rel) );

=head2 new PARAMHASH OVERRIDE

Create a new C<Jifty::Web::Form::Element> object blessed with
PARAMHASH, and set with accessors for the hash values in OVERRIDE.

=cut

sub new {
    my ($class, $args, $other) = @_;
    $args = {%{$args}, %{$other || {}}};
    # force using accessor for onclick init
    my $override = {};
    $override->{$_} = delete $args->{$_}
        for grep {possible_handlers->{$_} and defined $args->{$_}} keys %{$args};

    my $self = $class->SUPER::new($args);

    $self->{handlers_used} = {};
    $self->$_( $override->{$_} ) for keys %{$override};

    return $self;
}

__PACKAGE__->_mk_normalising_accessor($_) for __PACKAGE__->handlers;

sub _mk_normalising_accessor {
    my ($class, $accessor) = @_;
    my $internal_method = "_$accessor";
    no strict 'refs';
    *{$accessor} = sub {
        my $self = shift;
        return $self->{$internal_method} unless @_;

        $self->$internal_method($self->_handler_setup($internal_method, @_));
    };
}

=head2 onclick

The onclick event occurs when the pointing device button is clicked 
over an element. This attribute may be used with most elements.

=head2 onchange

The onchange event occurs when a control loses the input focus 
and its value has been modified since gaining focus. This handler 
can be used with all form elements.

=head2 ondblclick

The ondblclick event occurs when the pointing device button is 
double clicked over an element.  This handler 
can be used with all form elements.

=head2 onmousedown

The onmousedown event occurs when the pointing device button is 
pressed over an element.  This handler 
can be used with all form elements.

=head2 onmouseup

The onmouseup event occurs when the pointing device button is released 
over an element.  This handler can be used with all form elements.

=head2 onmouseover

The onmouseover event occurs when the pointing device is moved onto an 
element.  This handler can be used with all form elements.

=head2 onmousemove

The onmousemove event occurs when the pointing device is moved while it 
is over an element.  This handler can be used with all form elements.

=head2 onmouseout

The onmouseout event occurs when the pointing device is moved away from 
an element.  This handler can be used with all form elements.

=head2 onfocus

The onfocus event occurs when an element receives focus either by the 
pointing device or by tabbing navigation.  This handler 
can be used with all form elements.

=head2 onblur

The onblur event occurs when an element loses focus either by the pointing 
device or by tabbing navigation.  This handler can be used with all 
form elements.

=head2 onkeypress

The onkeypress event occurs when a key is pressed and released over an 
element.  This handler can be used with all form elements.

=head2 onkeydown

The onkeydown event occurs when a key is pressed down over an element. 
This handler can be used with all form elements.

=head2 onkeyup

The onkeyup event occurs when a key is released over an element. 
This handler can be used with all form elements.
=cut

=head2 onselect

The onselect event occurs when a user selects some text in a text field. 
This attribute may be used with the text and textarea fields.

=head2 _handler_setup

This method is used by all handlers to normalize all arguments.

=cut

sub _handler_setup {
    my $self = shift;
    my $trigger = shift;

    return $self->$trigger unless @_;
    $trigger =~ s/^_//;
    $self->{handlers_used}{$trigger} = 1;

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

            my @submit_tmp;
            foreach my $submit ( @{$hook->{submit}}) {
                if (!ref($submit)) {
                    push @submit_tmp, $submit;
                } elsif(blessed($submit)) {
                    push @submit_tmp, $submit->moniker;
                } else { # it's a hashref
                    push @submit_tmp, $submit->{'action'}->moniker;
                    $hook->{'action_arguments'}->{ $submit->{'action'}->moniker } = $submit->{'arguments'};
                }

            }

            @{$hook->{submit}} =  @submit_tmp;
        }

        $hook->{args} ||= $hook->{arguments}; # should be able to use 'arguments' and not lose.

        if ( $hook->{args} ) {
            # We're going to pass complex query mapping structures
            # as-is to the server, but we need to make sure we're not
            # trying to pass around Actions, merely their monikers.
            for my $key ( keys %{ $hook->{args} } ) {
                next unless ref $hook->{args}{$key} eq "HASH";
                $hook->{args}{$key}{$_} = $hook->{args}{$key}{$_}->moniker for grep { ref $hook->{args}{$key}{$_} } keys %{ $hook->{args}{$key} };
            }
        } else {
            $hook->{args} = {};
        }

    }

    return $arg;

}

=head2 handlers_used

Returns the names of javascript handlers which exist for this element.

=cut

sub handlers_used {
    my $self = shift;
    return keys %{$self->{handlers_used}};
}

=head2 javascript

Returns the javascript necessary to make the events happen, as a
string of HTML attributes.

=cut

sub javascript {
    my $self = shift;
    my %response = $self->javascript_attrs;
    return join "", map {qq| $_="| . Jifty->web->escape($response{$_}).qq|"|} sort keys %response;
}

=head2 javascript_attrs

Returns the javascript necessary to make the events happen, as a
hash of attribute-name and value.

=cut

sub javascript_attrs {
    my $self = shift;

    my %response;

  HANDLER:
    for my $trigger ( $self->handlers_used ) {
        # Walk around the Class::Accessor, for speed
        my $value = $self->{"_$trigger"};
        next unless $value;

        if ( !( $self->handler_allowed($trigger) ) ) {
            $self->log->error(
                      "Handler '$trigger' is not supported for field '"
                    . $self->label
                    . "' with class "
                    . ref $self );
            next;
        }

        my @fragments;
            # if $actions is undef, that means we're submitting _all_ actions in the clickable
            # if $actions is defined but empty, that means we're submitting no actions
            # if $actions is not empty, we're submitting those actions
        my $actions = {};    # Maps actions => disable?
        my $confirm;
        my $beforeclick;
        my $action_arguments = {};
        for my $hook (grep {ref $_ eq "HASH"} (@{$value})) {
            my %args;

            # Submit action
            if ( exists $hook->{submit} ) {
                $actions = undef;
                my $disable_form_on_click = exists $hook->{disable} ? $hook->{disable} : 1;
                # Normalize to 1/0 to pass to JS
                $disable_form_on_click = $disable_form_on_click ? 1 : 0;
                for (@{ $hook->{submit} || [] }) {
                    $actions->{$_} = $disable_form_on_click;
                    $action_arguments->{$_} = $hook->{'action_arguments'}->{$_};
                }

            }

            $hook->{region} ||= Jifty->web->qualified_region;

            # Should we show a javascript confirm message?
            if ($hook->{confirm}) {
                $confirm = $hook->{confirm};
            }

            # Some code usable before onclick
            if ($hook->{beforeclick}) {
                $beforeclick = $hook->{beforeclick};
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
                    $self->log->warn("Can't find region ".$hook->{refresh});
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

            # Preloading functionality
            $args{preload} = 1 if $hook->{preload};

            # Effects
            $args{$_} = $hook->{$_} for grep {exists $hook->{$_}} qw/effect effect_args remove_effect remove_effect_args/;

            push @fragments, \%args;
        }

        my $string = join ";", grep {not ref $_} @{$value};
        if ( @fragments or ( !$actions || %$actions ) ) {

            my $update =
                "Jifty.update( "
                    . Jifty::JSON::objToJson(
                    {   actions      => $actions,
                        action_arguments => $action_arguments,
                        fragments    => \@fragments,
                        continuation => $self->continuation
                    },
                    { singlequote => 1 }
                    ) . ", this );";
            $string
                .= 'if(event.ctrlKey||event.metaKey||event.altKey||event.shiftKey) return true; '
                if ( $trigger eq 'onclick' );
            $string .= $self->javascript_preempt
                ? "return $update"
                : "$update; return true;";
        }
        if ($confirm) {
            my $text = Jifty::JSON::objToJson($confirm, {singlequote => 1});
            $string = "if(!confirm($text)){ Jifty.stopEvent(event); return false; }" . $string;
        }
        if ($beforeclick) {
           $string = $beforeclick . $string;
        }
        $response{$trigger} = $string;
    }
    return %response;
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

=head2 title

Sets the title that the element will display, e.g. for tooltips

=head2 key_binding

Sets the key binding associated with this element

=head2 key_binding_label

Sets the key binding label associated with this element (if none is specified,
the normal label is used instead)

=head2 id

Subclasses must override this to provide each element with a unique id.

=head2 label

Sets the label of the element.  This will be used for the key binding
legend if key_binding_label is not set.

=head2 key_binding_javascript

Returns the javascript fragment to add key binding for this input, if
one exists.

=cut

sub key_binding_javascript {
    my $self  = shift;
    my $key   = $self->key_binding;
    my $label = defined $self->key_binding_label
                    ? $self->key_binding_label
                    : $self->label;
    if ($key) {
        return "Jifty.KeyBindings.add("
                . Jifty::JSON::objToJson( uc($key), { singlequote => 1 } ).","
                . "'click', "
                . Jifty::JSON::objToJson( $self->id, { singlequote => 1 } ).","
                . Jifty::JSON::objToJson( $label, { singlequote => 0 } )
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
        '<script type="text/javascript">' .
        Jifty->web->escape($self->key_binding_javascript).
        "</script>");
    return '';
}


=head2 handler_allowed HANDLER_NAME

Returns 1 if the handler (e.g. onclick) is allowed.  Undef otherwise.

The set defined here represents the typical handlers that are 
permitted.  Derived classes should override if they stray from the norm.

By default we allow:

onchange onclick ondblclick onmousedown onmouseup onmouseover onmousemove 
onmouseout onfocus onblur onkeypress onkeydown onkeyup

=cut

sub handler_allowed {
    my $self = shift;
    my ($handler) = @_;

    return {onchange => 1, 
            onclick => 1, 
            ondblclick => 1, 
            onmousedown => 1,
            onmouseup => 1,
            onmouseover => 1,
            onmousemove => 1,
            onmouseout => 1,
            onfocus => 1,
            onblur => 1,
            onkeypress => 1,
            onkeydown => 1,
            onkeyup => 1
           }->{$handler};

}
 


1;
