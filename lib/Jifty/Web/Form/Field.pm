=begin properties

constructor
canonicalizer
available_values
ajax_validates
autocompleter

default_value
valid_values
validator
render_as
label
hints
placeholder
display_length
max_length
mandatory

=end properties

=cut

use warnings;
use strict;
 
package Jifty::Web::Form::Field;

=head1 NAME

Jifty::Web::Form::Field - Web input of some sort

=head1 DESCRIPTION

Describes a form input in a L<Jifty::Action>.
C<Jifty::Web::Form::Field>s know what action they are on, and aquire
properties from the L<Jifty::Action> which they are part of.  Each key
in the L<Jifty::Action/arguments> hash becomes a
C<Jifty::Web::Form::Field> whose L</name> is that key.

C<Jifty::Web::Form::Field>s stringify using the L</render> method, to
aid in placing them in L<HTML::Mason> components.

=cut

use base 'Jifty::Web::Form::Element';

use Scalar::Util qw/weaken/;
use Scalar::Defer qw/force/;
use HTML::Entities;

# We need the anonymous sub because otherwise the method of the base class is
# always called, instead of the appropriate overridden method in a child class.
use overload '""' => sub { shift->render }, bool => sub { 1 };

=head2 new

Creates a new L<Jifty::Web::Form::Field> (possibly magically blessing into a subclass).
Should only be called from C<< $action->arguments >>.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(
      { type          => 'text',
        class         => '',
        input_name    => '',
        default_value => '',
        sticky_value  => '',
        render_mode   => 'update' });
    my $args = ref($_[0]) ? $_[0] : {@_};

    $self->rebless( $args->{render_as} || $args->{type} || 'text' );

    for my $field ( $self->accessors() ) {
        $self->$field( $args->{$field} ) if exists $args->{$field};
    }

    # If they key and/or value imply that this argument is going to be
    # a mapped argument, then do the mapping and mark the field as hidden.
    # but ignore that if the field is a container in the model
    my ($key, $value) = Jifty::Request::Mapper->query_parameters($self->input_name, $self->current_value);
    if ($key ne $self->input_name && !$self->action->arguments->{$self->name}{container}) {
        $self->rebless('Hidden');
        $self->input_name($key);
        $self->default_value($value);
        $self->sticky_value(undef);
    }

    # now that the form field has been instantiated, register the action with the form.
    if ($self->action and Jifty->web->form->is_open and not (Jifty->web->form->printed_actions->{$self->action->moniker})) {
        Jifty->web->form->register_action( $self->action);
        Jifty->web->form->print_action_registration($self->action->moniker);
    }
    return $self;
}

=head2 $self->rebless($widget)

Turn the current blessed class into the given widget class.

=cut

sub rebless {
    my ($self, $widget) = @_;
    my $widget_class = $widget =~ m/::/ ? $widget : "Jifty::Web::Form::Field::".ucfirst($widget);

    $self->log->error("Invalid widget class $widget_class")
        unless Jifty::Util->require($widget_class);

    bless $self, $widget_class;
}

=head2 accessors

Lists the accessors that are able to be called from within a call to
C<new>.  Subclasses should extend this list.

=cut

my @new_fields = qw(
    name type sticky sticky_value default_value action
    mandatory ajax_validates ajax_canonicalizes autocompleter preamble hints
    placeholder focus render_mode display_length max_length _element_id
    disable_autocomplete multiple
);

my @semiexposed_fields = qw(
    label input_name
);

sub accessors {
    shift->SUPER::accessors(), @new_fields, @semiexposed_fields;
}

__PACKAGE__->mk_accessors(@new_fields, map { "_$_" } @semiexposed_fields);

=head2 name [VALUE]

Gets or sets the name of the field.  This is seperate from the name of
the label (see L</label>) and the form input name (see
L</input_name>), though both default to this name.  This name should
match to a key in the L<Jifty::Action/arguments> hash.  If this
C<Jifty::Web::Form::Field> was created via L<Jifty::Action/form_field>,
this is automatically set for you.

=head2 class [VALUE]

Gets or sets the CSS display class applied to the label and widget.

=head2 type [VALUE]

Gets or sets the type of the HTML <input> field -- that is, 'text' or
'password'.  Defauts to 'text'.

=head2 key_binding VALUE

Sets this form field's "submit" key binding to VALUE. 

=head2 key_binding_label VALUE

Sets this form field's key binding label to VALUE.  If none is specified
the normal label is used.

=head2 default_value [VALUE]

Gets or sets the default value for the form.

=head2 sticky_value [VALUE]

Gets or sets the value for the form field that was submitted in the last action.

=head2 mandatory [VALUE]

A boolean indicating that the argument B<must> be present when the
user submits the form.

=head2 focus [VALUE]

If true, put focus on this form field when the page loads.

=head2 ajax_validates [VALUE]

A boolean value indicating if user input into an HTML form field for
this argument should be L<validated|Jifty::Manual::Glossary/validate>
via L<AJAX|Jifty::Manual::Glossary/AJAX> as the user fills out the
form, instead of waiting until submit. Arguments will B<always> be
validated before the action is run, whether or not they also
C<ajax_validate>.

=head2 ajax_canonicalizes [VALUE]

A boolean value indicating if user input into an HTML form field for
this argument should be L<canonicalized|Jifty::Manual::Glossary/canonicalize>
via L<AJAX|Jifty::Manual::Glassary/AJAX> as the user fills out the
form, instead of waiting until submit.  Arguments will B<always> be
canonicalized before the action is run, whether or not they also
C<ajax_canonicalize>

=head2 disable_autocomplete [VALUE]

Gets or sets whether to disable _browser_ autocomplete for this field.

=head2 preamble [VALUE]

Gets or sets the preamble located in front of the field.

=head2 multiple [VALUE]

A boolean indicating that the field is multiple.
aka. has multiple attribute, which is uselful for select field.

=head2 id 

For the purposes of L<Jifty::Web::Form::Element>, the unique id of
this field is its input name.

=cut

sub id {
    my $self = shift;
    return $self->input_name;
}

=head2 input_name [VALUE]

Gets or sets the form field input name, as it is rendered in the HTML.
If we've been explicitly named, return that, otherwise return a name
based on the moniker of the action and the name of the form.

=cut

sub input_name {
    my $self = shift;

# If we've been explicitly handed a name, we should run with it.
# Otherwise, we should ask our action, how to turn our "name"
# into a form input name.

    my $ret = $self->_input_name(@_);
    return $ret if $ret;

    my $action = $self->action;
    return $action ? $self->action->form_field_name( $self->name )
                   : '';
}


=head2 fallback_name

Return the form field's fallback name. This should be used to create a
hidden input with a value of 0 to accompany checkboxes or to let 
comboboxes fall back to the text input if, and only if no value is
selected from the SELECT.  (We use this order, so that we can stick the
label and not the value in the INPUT field. To make that work, we also need
to clear the SELECT after the user types in the INPUT.

=cut

sub fallback_name {
    my $self = shift;

    if ($self->action) {
    return $self->action->fallback_form_field_name( $self->name );
    }
    else {
        # XXX TODO, we should have a more graceful way to compose these in the absence of an action
        my $name = $self->input_name;
        $name =~ s/^J:A:F/J:A:F:F/;
        return($name)
    }
}


=head2 label [VALUE]

Gets or sets the label on the field.  This defaults to the name of the
object.

=cut

sub label {
    my $self = shift;
    my $val = $self->_label(@_);
    defined $val ? $val :  $self->name;

}

=head2 hints [VALUE]

Hints for the user to explain this field

=cut

sub hints {
    my $self = shift;
    return $self->_hints_accessor unless @_;

    my $hint = shift;
    # people sometimes say hints are "foo" rather than hints is "foo"
    if (ref $hint eq 'ARRAY') {
        $hint = shift @$hint;
    }
    return $self->_hints_accessor($hint);
}


=head2 element_id 

Returns a unique C<id> attribute for this field based on the field name. This is
consistent for the life of the L<Jifty::Web::Form::Field> object but isn't predictable;

=cut


sub element_id {
    my $self = shift;
    return $self->_element_id || $self->_element_id( $self->input_name ."-".Jifty->web->serial); 
}

=head2 action [VALUE]

Gets or sets the L<Jifty::Action> object that this
C<Jifty::Web::Form::Field> is associated with.  This is called
automatically if this C<Jifty::Action> was created via
L<Jifty::Web::Form::Field/form_field>.

=cut

sub action {
    my $self = shift;

    if (@_) {
        $self->{action} = shift;

        # weaken our circular reference
        weaken $self->{action};
    }

    return $self->{action};

}

=head2 current_value

Gets the current value we should be using for this form field.

If the argument is marked as "sticky" (default) and there is a value for this 
field from a previous action submit AND that action did not have a "success" 
response, returns that submit's value. Otherwise, returns the action's argument's 
default_value for this field.

=cut

sub current_value {
    my $self = shift;

    if ($self->sticky_value and $self->sticky) {
        return $self->sticky_value;
    } else {
        # the force is here because very often this will be a Scalar::Defer object that we REALLY 
        # want to be able to check definedness on.
        # Because of a core limitation in perl, Scalar::Defer can't return undef for an object.
        return force $self->default_value;
    }
}

=head2 render

Outputs this form element in a span with class C<form_field>.  This
outputs the label, the widget itself, any hints, any errors, and any
warnings using L</render_label>, L</render_widget>, L</render_hints>,
L</render_errors>, and L</render_warnings>, respectively.  Returns an
empty string.

This is also what C<Jifty::Web::Form::Field>s do when stringified.

=cut

sub render {
    my $self = shift;
    $self->render_wrapper_start();
    $self->render_preamble();


    $self->render_label();
    if ($self->render_mode eq 'update') { 
        $self->render_widget();
        $self->render_autocomplete_div();
        $self->render_inline_javascript();
        $self->render_hints();
        $self->render_errors();
        $self->render_warnings();
        $self->render_canonicalization_notes();
    } elsif ($self->render_mode eq 'read'){ 
        $self->render_value();
        $self->render_preload_javascript();
    }
    $self->render_wrapper_end();
    return ('');
}

=head2 render_inline_javascript

Render a <script> tag (if necessary) containing any inline javascript that
should follow this form field. This is used to add an autocompleter,
placeholder, keybinding, or preloading to form fields where needed.

=cut

sub render_inline_javascript {
    my $self = shift;

    my $javascript;

    $javascript = join(
        "\n",
        grep {$_} (
            $self->autocomplete_javascript(),
            $self->placeholder_javascript(),
            $self->key_binding_javascript(),
            $self->focus_javascript(),
            $self->preload_javascript(),
        )
    );
    
    if($javascript =~ /\S/) {
        Jifty->web->out(qq{<script type="text/javascript">$javascript</script>
});
    }
}

=head2 render_preload_javascript

Render a <script> tag (if necessary) containing any inline preload javascript
that should follow this form field.

=cut

sub render_preload_javascript {
    my $self = shift;

    my $javascript = $self->preload_javascript;

    if($javascript =~ /\S/) {
        Jifty->web->out(qq{<script type="text/javascript">$javascript</script>
});
    }
}

=head2 classes

Renders a default CSS class for each part of our widget.

=cut


sub classes {
    my $self = shift;
    my $name = $self->name;
    return join(' ', ($self->class||''), ($name ? "argument-".$name : ''));
}


=head2 render_wrapper_start

Output the start of div that wraps the form field

=cut

sub render_wrapper_start {
    my $self = shift;
    my @classes = qw(form_field);
    if ($self->mandatory) { push @classes, 'mandatory' }
    if ($self->name)      { push @classes, 'argument-'.$self->name }
    Jifty->web->out('<div class="'.join(' ', @classes).'">' ."\n");
}

=head2 render_wrapper_end

Output the div that wraps the form field

=cut

sub render_wrapper_end {
    my $self = shift;
    Jifty->web->out("</div>"."\n");
}

=head2 render_preamble

Outputs the preamble of this form field, using a <span> HTML element
with CSS class C<preamble> and whatever L</class> specifies.  Returns an
empty string.

Use this for sticking instructions right in front of a widget

=cut


sub render_preamble {
    my $self = shift;
    Jifty->web->out(
qq!<span class="preamble @{[$self->classes]}">@{[_($self->preamble) || '' ]}</span>\n!
    );

    return '';
}

=head2 render_label

Outputs the label of this form field, using a <label> HTML element
with the CSS class C<label> and whatever L</class> specifies.  Returns
an empty string.

=cut

sub render_label {
    my $self = shift;
    return '' unless defined $self->label and length $self->label;
    if ( $self->render_mode eq 'update' ) {
        Jifty->web->out(
qq!<label class="label @{[$self->classes]}" for="@{[$self->element_id ]}">@{[_($self->label) ]}</label>\n!
        );
    } else {
        Jifty->web->out(
            qq!<span class="label @{[$self->classes]}">@{[_($self->label) ]}</span>\n!
        );
    }

    return '';
}


=head2 render_widget

Outputs the actual entry widget for this form element.  This defaults
to an <input> element, though subclasses commonly override this.
Returns an empty string.

=cut

sub render_widget {
    my $self  = shift;
    my $field = qq!  <input !;
    $field .= qq! type="@{[ $self->type ]}"!;
    $field .= qq! name="@{[ $self->input_name ]}"! if ($self->input_name);
    $field .= qq! title="@{[ $self->title ]}"! if ($self->title);
    $field .= qq! id="@{[ $self->element_id ]}"!;
    $field .= qq! value="@{[$self->canonicalize_value(Jifty->web->escape($self->current_value))]}"! if defined $self->current_value;
    $field .= $self->_widget_class; 

    if ($self->display_length) {
        $field .= qq! size="@{[ $self->display_length() ]}"!;
    }
    elsif ($self->max_length) {
        $field .= qq! size="@{[ $self->max_length() ]}"!;
    }

    $field .= qq! maxlength="@{[ $self->max_length() ]}"! if ($self->max_length());
    $field .= qq! autocomplete="off"! if defined $self->disable_autocomplete;
    $field .= " " .$self->other_widget_properties;
    $field .= $self->javascript;
    $field .= qq!  />\n!;
    Jifty->web->out($field);
    return '';
}


=head2 canonicalize_value

Called when a value is about to be displayed. Can be overridden to, for example,
display only the yyyy-mm-dd portion of a DateTime.

=cut

sub canonicalize_value {
    my $self = shift;
    return $_[0];
}

=head2 other_widget_properties

If your widget subclass has other properties it wants to insert into the html
of the main widget and you haven't subclassed render_widget then you can just
subclass this.

If you have subclassed render_widget then just stick them in your local sub
render_widget.

We use this for marking password fields as not-autocomplete so the browser does
not try to use its form autocompletion on them.


=cut

sub other_widget_properties {''}

=head2 _widget_class

Returns the "class=" line for our widget. Optionally takes extra classes to append to our list.

=cut

sub _widget_class {
    my $self = shift;
    my @classes = ( 'widget',
                    $self->classes,
                    ( $self->ajax_validates     ? ' ajaxvalidation' : '' ),
                    ( $self->ajax_canonicalizes ? ' ajaxcanonicalization' : '' ),
                    ( $self->autocompleter      ? ' ajaxautocompletes' : '' ),
                    ( $self->focus              ? ' focus' : ''),
                    @_ );

    return qq! class="!. join(' ',@classes).  qq!"!

}

=head2 render_value

Renders a "view" version of the widget for field. Usually, this is just plain text.

=cut


sub render_value {
    my $self  = shift;
    my $field = '<span';
    $field .= qq! class="@{[ $self->classes ]} value"> !;
    # XXX: force stringify the value because maketext is buggy with overloaded objects.
    $field .= $self->canonicalize_value(Jifty->web->escape("@{[$self->current_value]}")) if defined $self->current_value;
    $field .= qq!</span>\n!;
    Jifty->web->out($field);
    return '';
}



=head2 render_autocomplete_div

Renders an empty div that /__jifty/autocomplete.xml can fill
in. Returns an empty string.

=cut

sub render_autocomplete_div { 
    my $self = shift;
    return unless($self->autocompleter);
    Jifty->web->out(
qq!<div class="autocomplete" id="@{[$self->element_id]}-autocomplete" style="display: none;"></div>!);

    return '';
}

=head2 render_autocomplete

Renders the div tag and javascript necessary to do autocompletion for
this form field. Deprecated internally in favor of
L</render_autocomplete_div> and L</autocomplete_javascript>, but kept
for backwards compatability since there exists external code that uses
it.

=cut

sub render_autocomplete {
    my $self = shift;
    return unless $self->autocompleter;
    $self->render_autocomplete_div;
    Jifty->web->out(qq!<script type="text/javascript">@{[$self->autocomplete_javascript]}</script>!);
    return '';
}



=head2 autocomplete_javascript

Returns renders the tiny snippet of javascript to make an autocomplete
call, if necessary.

=cut

sub autocomplete_javascript {
    my $self = shift;
    return unless($self->autocompleter);
    my $element_id = $self->element_id;
    return qq{new Jifty.Autocompleter('$element_id','$element_id-autocomplete')};
}

=head2 placeholder_javascript

Returns the javascript necessary to insert a placeholder into this
form field (greyed-out text that is written in using javascript, and
vanishes when the user focuses the field). 

=cut

sub placeholder_javascript {
    my $self = shift;
    return unless $self->placeholder;
    my $placeholder = $self->placeholder;
    $placeholder =~ s{(['\\])}{\\$1}g;
    $placeholder =~ s{\n}{\\n}g;
    $placeholder =~ s{\r}{\\r}g;
    return qq!new Jifty.Placeholder('@{[$self->element_id]}', '$placeholder');!;
}

=head2 focus_javascript

Returns the javascript necessary to focus this form field on page
load, if necessary.

=cut

sub focus_javascript {
    my $self = shift;
    return undef;
    if($self->focus) {
        return qq!document.getElementById("@{[$self->element_id]}").focus()!;
        return qq!DOM.Events.addListener( window, "load", function(){document.getElementById("@{[$self->element_id]}").focus()})!;
    }
}

=head2 preload_javascript

Returns the javascript necessary to load regions that have been marked for
preloading, as plain javascript. The L</javascript> method will look for
regions marked with preloading and swap them in, instead of loading them
directly.

=cut

sub preload_javascript {
    my $self = shift;

    my $structure = $self->_javascript_attrs_structure;
    my @preloaded;

    for my $trigger (keys %$structure) {
        my $trigger_structure = $structure->{$trigger};
        my $fragments = $trigger_structure->{fragments};

        for my $fragment (@$fragments) {
            next unless $fragment->{preload};
            push @preloaded, $fragment;
        }
    }

    return if !@preloaded;

    # If we're inside a preloaded region, then we don't want to preload any
    # other regions. Otherwise you could get into a cycle where you're always
    # preloading the same set of regions. So we set it up so that when this
    # preloaded region is put into the page, it will preload its child regions.
    if (Jifty->web->request->preloading_region) {
        my $region = Jifty->web->current_region->qualified_name;
        return;
    }

    my $preload_json = Jifty::JSON::objToJson(
        { fragments   => \@preloaded },
        { singlequote => 1 },
    );

    return "Jifty.preload($preload_json, this);";
}

=head2 render_hints

Renders any hints for using this input.  Defaults to nothing, though
subclasses commonly override this.  Returns an empty string.

=cut

sub render_hints { 
    my $self = shift;
    Jifty->web->out(
qq!<span class="hints @{[$self->classes]}">@{[_($self->hints) || '']}</span>\n!
    );

    return '';

}


=head2 render_errors

Outputs a <div> with any errors for this action, even if there are
none -- AJAX could fill it in.

=cut

sub render_errors {
    my $self = shift;

    return unless $self->action;

    Jifty->web->out(
qq!<span class="error @{[$self->classes]}" id="@{[$self->action->error_div_id($self->name)]}">@{[  $self->action->result->field_error( $self->name ) || '']}</span>\n!
    );
    return '';
}

=head2 render_warnings

Outputs a <div> with any warnings for this action, even if there are
none -- AJAX could fill it in.

=cut

sub render_warnings {
    my $self = shift;

    return unless $self->action;

    Jifty->web->out(
qq!<span class="warning @{[$self->classes]}" id="@{[$self->action->warning_div_id($self->name)]}">@{[  $self->action->result->field_warning( $self->name ) || '']}</span>\n!
    );
    return '';
}

=head2 render_canonicalization_notes

Outputs a <div> with any canonicalization notes for this action, even if there are
none -- AJAX could fill it in.

=cut

sub render_canonicalization_notes {
    my $self = shift;

    return unless $self->action;

    Jifty->web->out(
qq!<span class="canonicalization_note @{[$self->classes]}" id="@{[$self->action->canonicalization_note_div_id($self->name)]}">@{[$self->action->result->field_canonicalization_note( $self->name ) || '']}</span>\n!
    );
    return '';
}

=head2 available_values

Returns the available values for this field.

=cut

sub available_values {
    my $self = shift;
    return @{ $self->action->available_values($self->name) };
}

=for private

=head2 length

# Deprecated API


=cut

sub length {
    my $self = shift;
    Carp::carp("->length is deprecated; use ->max_length instead");
    $self->max_length(@_);
}


1;
