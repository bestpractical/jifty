use warnings;
use strict;

package Jifty::Action;

=head1 NAME

Jifty::Action - The ability to Do Things in the framework

=head1 DESCRIPTION

C<Jifty::Action> is the meat of the L<Jifty> framework; it controls how
form elements interact with the underlying model.

=cut


use base qw/Jifty::Object Class::Accessor/;

__PACKAGE__->mk_accessors(qw(moniker just_validating argument_values order result));

=head2 new

Construct a new action.  (Subclasses who need do custom initialization
should start with C<my $class = shift; my $self = $class->SUPER::new(@_)>.)

Arguments: C<moniker> and C<arguments>.

B<Do not call this yourself>; always go through C<< framework->new_action >>!

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    my %args = (
        moniker    => 'random-moniker-'.int(rand(99999)),
        order      => undef,
        arguments  => {},
        @_);

    $self->moniker($args{'moniker'});
    $self->order($args{'order'});
    $self->argument_values( { %{ $args{'arguments'} } } );
    $self->result(Jifty->framework->response->result($self->moniker) || Jifty::Result->new);
    $self->result->action_class(ref($self));

    return $self;
}

=head1 COMMON METHODS

=head2 arguments

This method, along with L</take_action>, is the most commonly
overridden method.  It should return a hash which describes the
arguments this action takes:

  {
    argument_name    => {label => "properties go in this hash"},
    another_argument => {mandatory => 1}
  }

Each argument listed in the hash will be turned into a
L<Jifty::Web::Form::Field> object.  For each argument, the hash that
describes it is used to set up the L<Jifty::Web::Form::Field> object by
calling the keys as methods with the values as arguments.  That is, in
the above example, Jifty will run code similar to the following:

  # For 'argument_name'
  $f = Jifty::Web::Form::Field->new;
  $f->name( "argument_name" );
  $f->label( "Properties go in this hash" );

If an action has parameters that B<must> be passed to it to execute,
these should have the C<constructor> property set.  This is separate
from the C<mandatory> property, which deal with requiring that the
user enter a value for that field.  See L<Jifty::Web::Form::Field>.

=cut

sub arguments {
    my  $self= shift;
    return {}
}


=head2 register

Registers this action as being present.  This expects that an HTML
form has already been opened.  Note that this is not a guarantee that
the action will be run, even if the form is submitted.  See
L<Jifty::Request> for the definition of "active" actions.

=cut

sub register {
    my $self = shift;
    Jifty->mason->out( qq!<input type="hidden"! .
                       qq! name="@{[$self->register_name]}"! .
                       qq! id="@{[$self->register_name]}"! .
                       qq! value="@{[ref($self)]}"! .
                       qq! />\n! );



    my %args = %{$self->arguments};

    while ( my ( $name, $info ) = each %args ) {
        next unless $info->{'constructor'};
        Jifty::Web::Form::Field->new(
            %$info,
            action        => $self,
            input_name    => $self->double_fallback_form_field_name($name),
            sticky       => 0,
            default_value => ($self->argument_value($name) || $info->{'default_value'}),
            render_as     => 'Hidden'
        )->render();
    }
    return '';
}


=head2 run

Checks authorization with L</check_authorization>, calls C</setup>,
canonicalizes each argument with L</canonicalize_arguments>,
validates the form fields that have been submitted using
L</validate_arguments>, calls L</take_action>, then calls
L</cleanup>.  Each step must return a true value, or C<run> will skip
any remaining steps.

=cut

sub run {
    my $self = shift;
    $self->check_authorization || return;
    $self->setup || return;
    $self->canonicalize_arguments || return;
    $self->validate_arguments || return;
    $self->take_action || return;
    $self->cleanup || return;
}

=head2 validate_as_xml

Validate this action's arguments and return some XML describing the errors.

The AJAX verification stuff uses this.

XXX TODO REALLY, this should be using Jifty::Record::Form::Field->render_error to do the rendering 
of the error divs. 



=cut

sub validate_as_xml {
    my $self = shift;
    $self->check_authorization || return;
    $self->just_validating(1);
    $self->setup || return;
    Jifty->mason->cgi_request->content_type("text/xml");
    Jifty->mason->out(qq{<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<validation id="@{[$self->register_name]}">\n});
    $self->validate_arguments;
    Jifty->mason->out("</validation>\n");

}

=head2 check_authorization

Returns true if whoever invoked this action is authorized to perform
this action. 

By default, returns true.

=cut

sub check_authorization { 1; }


=head2 setup

Whatever the action needs to do to set itself up, it can do it by
overriding C<setup>.  C<setup> is expected to return a true value, or
L</run> will skip all other actions.

By default, does nothing.

=cut

sub setup { 1; }


=head2 take_action

Do whatever the action is supposed to do.  This and
L</arguments> are the most commonly overridden methods.

By default, does nothing.

=cut

sub take_action { 1; }


=head2 cleanup

Perform any action specific cleanup.  By default, does nothing.

=cut

sub cleanup { 1; }


=head2 argument_value FIELDNAME [VALUE]

Returns the value from the request of the given argument name, for
this action.  If I<VALUE> is set, sets the value.

=cut

sub argument_value {
    my $self = shift;
    my $arg = shift;

    $self->argument_values->{$arg} = shift if @_;
    return $self->argument_values->{$arg};
}


=head2 form_field ARGUMENT_NAME

Returns a Jifty::Web::Form::Field object for this argument.  If there
is no entry in the L</arguments> hash that matches the given
C<FIELDNAME>, returns C<undef>.

=cut


sub form_field {
    my $self = shift;
    my $arg_name = shift;
    $self->_form_widget( argument => $arg_name,
                         render_mode => 'update',
                         @_);

}


=head2 form_value ARGUMENT_NAME

Returns a Jifty::Web::Form::Field object that renders a display value instead of an editable widget for this argument.  If there
is no entry in the L</arguments> hash that matches the given
C<FIELDNAME>, returns C<undef>.

=cut



sub form_value {
    my $self = shift;
    my $arg_name = shift;
    $self->_form_widget( argument => $arg_name,
                         render_mode => 'read',
                         @_);

}



sub _form_widget {
    my $self       = shift;
    my %args = ( argument => undef,
                 render_mode => 'update',
                 @_);


    my $arg_name = $args{'argument'}. '!!' .$args{'render_mode'};

    if ( not exists $self->{_private_form_fields_hash}{$arg_name} ) {

        my $field_info = $self->arguments->{$args{'argument'}};
        if ($field_info) {
            # form_fields overrides stickiness of what the user last entered.
            $self->{_private_form_fields_hash}{$arg_name}
                = Jifty::Web::Form::Field->new(
                action        => $self,
                name          => $args{'argument'},
                sticky       => 1, # default to sticky. an actual value in the action's arguments can override
                sticky_value => $self->argument_value($args{'argument'}),
                render_mode => $args{'render_mode'},
                %$field_info,
                %args
                );

            
        }    # else $field remains undef
        else {
            Jifty->log->warn("$arg_name isn't a valid field for $self");
        }
    } elsif ( $args{render_as} ) {
        bless $self->{_private_form_fields_hash}{$arg_name},
          "Jifty::Web::Form::Field::$args{render_as}";
    }
    return $self->{_private_form_fields_hash}{$arg_name};
}

=head2 order

Gets ot sets the order that the action will be run in.  This should be
a number, with lower numbers being run first.

=cut

=head2 result

Returns the L<Jifty::Result> method associated with this action.  This
information is stored in notes across a redirect, so the information
is still available.

=head2 render_errors

Render any errors for this action that were set using C<error> above.
Returns nothing.

=cut

sub render_errors {
    my $self = shift;
    my $m = Jifty->mason; 
    
    if (defined $self->result->error) {
        $m->out('<div class="form_errors">');
        # XXX TODO FIXME escape?
        $m->out('<span class="error">'. $self->result->error .'</span>');
        $m->out('</div>');
    }

    return '';
}

=head2 button { arguments => { PARAMHASH }, label => LABEL }

Create and render a button. 

turns  'arguments' paramhash into arguments passed to the action on submit.

paints LABEL onto the button

=cut

sub button {
    my $self = shift;
    my %args = ( arguments => {},
                 label => 'Click me!',
                 key_binding => undef,
                 @_);
    my $field = Jifty::Web::Form::Field->new( action => $self, label => $args{'label'}, type => 'InlineButton', key_binding => $args{'key_binding'});
    $field->input_name(join "|", map {$self->form_field_name($_)."=".$args{arguments}{$_}} keys %{$args{arguments}});
    $field->name(join '|', keys %{$args{arguments}}); # Only used internally

    return $field;

}

=head1 NAME METHODS

=head2 register_name

Returns the name of the "registration" query argument for this action
in a web form.

=cut

sub register_name {
    my $self = shift;
    return 'J:A-' . (defined $self->order ? $self->order . "-" : "") .$self->moniker;
}


=head2 form_field_name FIELDNAME

Turn one of this action's field names into a fully qualified name;
takes the name of the field as an argument.

Note that since it ends with a moniker (which can contain any
characters except semicolons), if you construct a string based on
C<form_field_name> which you later need to parse, the
C<form_field_name> must come at the end or you must do something with
semicolons.

=cut

sub form_field_name {
    my $self = shift;
    my $field_name = shift;
    return "J:A:F-$field_name-".$self->moniker;
}


=head2 fallback_form_field_name FIELDNAME

Turn one of this action's field names into a fully qualified
"fallback" name; takes the name of the field as an argument.

This is specifically to support checkboxes, which only show up in the
query string if they are checked.  If you create a checkbox with the
value of C<form_field_name> as its name and a value of 1, and a hidden
input with the value of C<fallback_form_field_name> as its name and a
value of 0, then the L<Jifty::Request> will contain the correct value
either way.

=cut

sub fallback_form_field_name {
    my $self = shift;
    my $field_name = shift;
    return "J:A:F:F-$field_name-".$self->moniker;
}


=head2 double_fallback_form_field_name FIELDNAME

Turn one of this action's field names into a fully qualified "double
fallback" name; takes the name of the field as an argument.

This is specifically to support "constructor" hidden inputs, which
need to be have even lower precedence than checkbox fallbacks.
Probably we need a more flexible system, though.

=cut

sub double_fallback_form_field_name {
    my $self = shift;
    my $field_name = shift;
    return "J:A:F:F:F-$field_name-".$self->moniker;
}


=head2 error_div_id FIELDNAME

Turn one of this action's parameters into the id for the div in
which its errors live; takes name of the field as an argument.

=cut

sub error_div_id {
  my $self = shift;
  my $field_name = shift;
  return 'errors-' . $self->form_field_name($field_name);
}


=head1 VALIDATION METHODS

=head2 argument_names

Returns the list of form field names.  This information is extracted
from L</arguments>.

=cut

sub argument_names {
    my $self = shift;
    return (keys %{$self->arguments});
}


=head2 canonicalize_arguments

Canonicalizes each of the arguments that this action knows about.

This is done by calling
L</canonicalize_argument> for each field described by L</arguments>

=cut

sub canonicalize_arguments {
    my $self   = shift;
    my @fields = $self->argument_names;

    my $all_fields_ok = 1;
    foreach my $field (@fields) {
        next unless exists $self->argument_values->{$field};
        unless ( $self->canonicalize_argument($field) ) {

            $all_fields_ok = 0;
        }
    }
    return $all_fields_ok;
}


=head2 canonicalize_argument FIELDNAME

Canonicalizes the value of an argument. 
If the arugment has an attribute named B<canonizalizer>, 
call the subroutine reference that attribute points points to.

If it doesn't have a B<canonicalizer> attribute, but the action has a canonicalize_FIELDNAME function,
also invoke that function.

=cut

sub canonicalize_argument {
    my $self  = shift;
    my $field = shift;

    my $field_info = $self->arguments->{$field};
    my $value = $self->argument_value($field);
    my $default_method = 'canonicalize_' . $field;

    if ( $field_info->{canonicalizer}
        and UNIVERSAL::isa( $field_info->{canonicalizer}, 'CODE' ) )
    {
        return $field_info->{canonicalizer}->( $self, $value );
    }

    elsif ( $self->can($default_method) ) {
        return $self->$default_method( $value );
    }

    # If none of the checks have failed so far, then it's ok
    else {
        return $field;
    }
}

=head2 validate_arguments

Validates the form fields.  This is done by calling
L</validate_argument> for each field described by L</arguments>

=cut

sub validate_arguments {
    my $self   = shift;
    my @fields = $self->argument_names;

    my $all_fields_ok = 1;
    foreach my $field (@fields) {
        unless ( $self->validate_argument($field) ) {

            $all_fields_ok = 0;
        }
    }
    return $all_fields_ok;
}


=head2 validate_argument FIELDNAME

Validate your form fields.  If the field FIELDNAME is mandatory,
checks for a value. If the field has an attribute named B<validator>, 
call the subroutine reference validator points to.

If the action doesn't have an explicit B<validator> attribute, but does have a 
validate_FIELDNAME function, invoke that function.


=cut

sub validate_argument {
    my $self  = shift;
    my $field = shift;

    my $field_info = $self->arguments->{$field};

    if ( $self->just_validating and not $field_info->{ajax_validates} ) {
        return $self->validation_ignored_xml($field);
    }

    my $value = $self->argument_value($field);

    if ( !defined $value || !length $value ) {

        # Never try to validate blank fields in AJAX
        if ( $self->just_validating ) {
            return $self->validation_blank_xml($field);
        }
        elsif ( $field_info->{mandatory} ) {
            return $self->validation_error( $field => "You need to fill in this field" );
        }
    }

    # If we have a set of allowed values, let's check that out.
    # XXX TODO this should be a validate_valid_values sub
    if ( $value && $field_info->{valid_values} ) {

        unless ( grep $_->{'value'} eq $value,
            @{ $self->valid_values($field) } )
        {

            return $self->validation_error(
                $field => q{That doesn't look like a correct value} );
        }

   # ... but still check through a validator function even if it's in the list
    }

    my $default_validator = 'validate_' . $field;

    # Finally, fall back to running a validator sub
    if ( $field_info->{validator}
        and UNIVERSAL::isa( $field_info->{validator}, 'CODE' ) )
    {
        return $field_info->{validator}->( $self, $value );
    }

    elsif ( $self->can($default_validator) ) {
        return $self->$default_validator( $value );
    }

    # If none of the checks have failed so far, then it's ok
    else {
        return $self->validation_ok($field);
    }
}

=head2 valid_values FIELD

Given a field name, returns the list of valid values for it, based on
its C<valid_values> parameter in the C<arguments> list.

If the parameter is not an array ref, just returns it (not sure if this
is ever OK except for C<undef>).  If it is an array ref, returns a new
array ref with each element converted into a hash with keys C<display>
and C<value>, which should be (if in a SELECT, say) the string to
display for the value, and the value to actually send to the server.
Things that are allowed in the array include hashes with C<display>
and C<value> (which are just sent through); hashes with C<collection>
(a L<Jifty::Collection>), and C<display_from> and C<value_from> (the names
of methods to call on each record in the collection to get C<display> and
C<value>); or strings, which are treated as both C<display> and C<value>.

(Avoid using this -- this is not the appropriate place for this logic
to be!)

=cut


# TODO XXX FIXME this is probably in the wrong place, logically

=head2 available_values FIELD


Just like valid_values, but if our action has a set of available recommended values, returns that
instead. (We use this to differentiate between a list of acceptable values and a list of suggested values.

=cut

sub available_values {
    my $self = shift;
    my $field = shift;

    $self->_values_for_field( $field => 'available' ) || $self->_values_for_field( $field => 'valid' );

}

sub valid_values {
    my $self = shift;
    my $field = shift;

    $self->_values_for_field( $field => 'valid' );
}

sub _values_for_field {
    my $self  = shift;
    my $field = shift;
    my $type = shift;

    my $vv_orig = $self->arguments->{$field}{$type .'_values'};
    return $vv_orig unless ref $vv_orig eq 'ARRAY';

    my $vv = [];

    for my $v (@$vv_orig) {
        if ( ref $v eq 'HASH' ) {
            if ( $v->{'collection'} ) {
                my $disp = $v->{'display_from'};
                my $val  = $v->{'value_from'};
                # XXX TODO: wrap this in an eval?
                push @$vv, map {
                    {
                        display => ( $_->$disp() || '' ),
                        value   => ( $_->$val()  || '' )
                    }
                } grep {$_->current_user_can("read")} @{ $v->{'collection'}->items_array_ref };

            }
            else {

                # assume it's already display/value
                push @$vv, $v;
            }
        }
        else {

            # just a string
            push @$vv, { display => $v, value => $v };
        }
    }

    return $vv;
}

=head2 validation_error FIELD => ERROR TEXT

If this is called inside a real form submission, sets the appropriate
Mason error notes field and returns 0.  If called inside an AJAX
validation, it returns the XML response.  FIELD is the unqualified name
of the field.

Inside a validator you should write:

  return $self->validation_error( $field => "error");

=cut

sub validation_error {
    my $self = shift;
    my $field = shift;
    my $error = shift;
  
    if ($self->just_validating) {
        # XXX FIXME TODO What if $error has ]]> in it?
        my $errdiv = $self->error_div_id($field);
        Jifty->mason->out(qq{<error id="$errdiv"><![CDATA[$error]]></error>\n});
    } else {
        $self->result->field_error($field => $error); 
    }
  
    return 0;
}

=head2 validation_ok FIELD

If this is called inside a real form submission, clears the appropriate Mason error notes field
and returns 1.
If called inside an AJAX validation, it the empty string.  FIELD is the unqualified
name of the field.

Inside a validator you should write:

  return $self->validation_ok($field);

=cut


sub validation_ok {
    my $self = shift;
    my $field = shift;

    if ($self->just_validating) {
        my $errdiv = $self->error_div_id($field);
        Jifty->mason->out(qq{<ok id="$errdiv" />\n});
    }

    return 1;
}

=head2 validation_blank_xml FIELD

Outputs a record in the XML validation response indicating that FIELD was blank.
Automatically called by C<validate_argument>; application code does not need to call it.

=cut

sub validation_blank_xml {
    my $self = shift;
    my $field = shift;

    if ($self->just_validating) {
        my $errdiv = $self->error_div_id($field);
        Jifty->mason->out(qq{<blank id="$errdiv" />\n});
    } else {
        $self->log->fatal(q{ # Shouldn't happen.});
    }

  return 1;
}

=head2 validation_ignored_xml FIELD

Outputs a record in the XML validation response indicating that FIELD was not
required to be validated.  Automatically called by C<validate_argument>;
application code does not need to call it.

=cut

sub validation_ignored_xml {
    my $self = shift;
    my $field = shift;

    if ($self->just_validating) {
        my $errdiv = $self->error_div_id($field);
        Jifty->mason->out(qq{<ignored id="$errdiv" />\n});
    } else {
        # Shouldn't happen.
        $self->log->fatal(q{ # Shouldn't happen.});
    }

    return 1;
}


1;
