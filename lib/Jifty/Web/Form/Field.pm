=for properties

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
length
mandatory


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

use base qw/Jifty::Web::Form::Element Class::Accessor/;

use Scalar::Util;
use HTML::Entities;
use overload '""' => sub {shift->render};

=head2 new

Creates a new L<Jifty::Web::Form::Field> (possibly magically blessing into a subclass).
Should only be called from C<< $action->arguments >>.

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;

    my %args = (
        type          => 'text',
        class         => '',
        input_name    => '',
        default_value => '',
        sticky_value  => '',
        render_mode   => 'update',
        @_,
    );

    my $subclass;
    if ($args{render_as}) {
        $subclass = ucfirst($args{render_as});
    } elsif ($args{'type'}) {
        $subclass = ucfirst($args{'type'});
    }
    if ($subclass) { 
        $subclass = 'Jifty::Web::Form::Field::' . $subclass unless $subclass =~ /::/;
        bless $self, $subclass if Jifty::Util->require($subclass);
    }

    for my $field ( $self->accessors() ) {
        $self->$field( $args{$field} ) if exists $args{$field};
    }

    # If they key and/or value imply that this argument is going to be
    # a mapped argument, then do the mapping and mark the field as hidden.
    my ($key, $value) = Jifty::Request::Mapper->query_parameters($self->input_name, $self->current_value);
    if ($key ne $self->input_name) {
        require Jifty::Web::Form::Field::Hidden;
        bless $self, "Jifty::Web::Form::Field::Hidden";
        $self->input_name($key);
        $self->default_value($value);
        $self->sticky_value(undef);
    }

    # now that the form field has been instantiated, register the action with the form.
    if ($self->action and not (Jifty->web->form->has_action($self->action))) {
        Jifty->web->form->register_action( $self->action);
        Jifty->web->form->print_action_registration($self->action->moniker);
    }
    return $self;
}


=head2 accessors

Lists the accessors that are able to be called from within a call to
C<new>.  Subclasses should extend this list.

=cut

sub accessors { shift->SUPER::accessors(), qw(name label input_name type sticky sticky_value default_value action mandatory ajax_validates autocompleter preamble hints render_mode length _element_id); }
__PACKAGE__->mk_accessors(qw(name _label _input_name type sticky sticky_value default_value _action mandatory ajax_validates autocompleter preamble hints render_mode length _element_id));

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


=head2 default_value [VALUE]

Gets or sets the default value for the form.

=head2 sticky_value [VALUE]

Gets or sets the value for the form field that was submitted in the last action.

=cut

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

    $self->_input_name(@_)
      || (
          $self->action
        ? $self->action->form_field_name( $self->name )
        : ''
      );
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
    my $self   = shift;
    my $action = $self->_action(@_);

    # If we're setting the action, we need to weaken
    # the reference to not get caught in a loop
    Scalar::Util::weaken( $self->{_action} ) if @_;
    return $action;
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
        return $self->default_value;
    }
}

=head2 render

Outputs this form element in a span with class C<form_field>.  This
outputs the label, the widget itself, any hints, and any errors, using
L</render_label>, L</render_widget>, L</render_hints>,
L</render_errors> respectively.  Returns an empty string.

This is also what C<Jifty::Web::Form::Field>s do when stringified.

=cut

sub render {
    my $self = shift;
    $self->render_wrapper_start();
    $self->render_preamble();


    $self->render_label();
    if ($self->render_mode eq 'update') { 
        $self->render_widget();
        $self->render_autocomplete();
        $self->render_key_binding();
        $self->render_hints();
        $self->render_errors();
    } elsif ($self->render_mode eq 'read'){ 
        $self->render_value();
    }
    $self->render_wrapper_end();
    return ('');
}


=head2 classes

Renders a default CSS class for each part of our widget.

=cut


sub classes {
    my $self = shift;
    return join(' ', ($self->class||''), ($self->name||''));
}


=head2 render_wrapper_start

Output the start of div that wraps the form field

=cut

sub render_wrapper_start {
    my $self = shift;
    my @classes = qw(form_field);
    if ($self->mandatory) { push @classes, 'mandatory' }
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
qq!<span class="preamble @{[$self->classes]}" >@{[$self->preamble || '' ]}</span>\n!
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
    Jifty->web->out(
qq!<label class="label @{[$self->classes]}" for="@{[$self->input_name ]}">@{[$self->label ]}</label>\n!
    );

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
    $field .= qq! name="@{[ $self->input_name ]}"!;
    $field .= qq! id="@{[ $self->element_id ]}"!;
    $field .= qq! value="@{[HTML::Entities::encode_entities($self->current_value)]}"! if defined $self->current_value;
    $field .= $self->_widget_class; 
    $field .= qq! size="@{[ $self->length() ]}"! if ($self->length());
    $field .= " " .$self->other_widget_properties;
    $field .= qq!  />\n!;
    Jifty->web->out($field);
    return '';
}

=head2 other_widget_properties

If your widget subclass has other properties it wants to insert into the html of the main widget and you haven't subclassed render_widget,

just stick them in your local sub render_widget.

We use this for marking password fields as not-autocomplete


=cut

sub other_widget_properties {''}

=head2 _widget_class

Returns the "class=" line for our widget. Optionally takes extra classes to append to our list.

=cut

sub _widget_class {
    my $self = shift;
    my @classes = ('widget', $self->classes, ($self->ajax_validates ? ' ajaxvalidation' : ''),@_);

    return qq! class="!. join(' ',@classes).  qq!"!

}

=head2 render_value

Renders a "view" version of the widget for field. Usually, this is just plain text.

=cut


sub render_value {
    my $self  = shift;
    my $field = '<span';
    $field .= qq! class="@{[ $self->classes ]}"> !;
    $field .= HTML::Entities::encode_entities($self->current_value) if defined $self->current_value;
    $field .= qq!</span>\n!;
    Jifty->web->out($field);
    return '';
}



=head2 render_autocomplete

Renders an empty div that /__jifty/autocomplete.xml can fill in. Also renders the tiny snippet
of javascript to make that call if necessary.
Returns an empty string.

=cut

sub render_autocomplete { 
    my $self = shift;
    return unless($self->autocompleter);
    Jifty->web->out(
qq!<div class="autocomplete" id="@{[$self->element_id]}-autocomplete" style="display:none;border:1px solid black;background-color:white;"></div>\n
        <script type="text/javascript">
          new Jifty.Autocompleter('@{[$self->element_id]}', '@{[$self->element_id]}-autocomplete', '/__jifty/autocomplete.xml')
        </script>
  !
    );

    return '';

}

=head2 render_hints

Renders any hints for using this input.  Defaults to nothing, though
subclasses commonly override this.  Returns an empty string.

=cut

sub render_hints { 
    my $self = shift;
    Jifty->web->out(
qq!<span class="hints @{[$self->classes]}">@{[$self->hints || '']}</span>\n!
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
qq!<span class="error @{[$self->classes]}" id="@{[$self->action->error_div_id($self->name)]}">
      @{[  $self->action->result->field_error( $self->name ) || '']}
    </span>\n!
    );
    return '';
}

1;
