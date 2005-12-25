use warnings;
use strict;

package Jifty::Action;

=head1 NAME

Jifty::Action - The ability to Do Things in the framework

=head1 DESCRIPTION

C<Jifty::Action> is the meat of the L<Jifty> framework; it controls
how form elements interact with the underlying model.  See also
L<Jifty::Action::Record> for data-oriented actions, L<Jifty::Result>
for how to return values from actions.

=cut


use base qw/Jifty::Object Class::Accessor/;

__PACKAGE__->mk_accessors(qw(moniker argument_values order result sticky_on_success sticky_on_failure));

=head1 COMMON METHODS

=head2 new 

Construct a new action.  Subclasses who need do custom initialization
should start with:

    my $class = shift; my $self = $class->SUPER::new(@_)

B<Do not call this yourself>; always go through C<<
Jifty->web->new_action >>!  The arguments that this will be
called with include:

=over

=item moniker

The L<moniker|Jifty::Manual::Glossary/moniker> of the action.  Defaults to an
autogenerated moniker.

=item order

An integer that determines the ordering of the action's execution.
Lower numbers occur before higher numbers.  Defaults to 0.

=item arguments

A hash reference of default values for the
L<arguments|Jifty::Manual::Glossary/arguments> of the action.  Defaults to
none.

=item sticky_on_failure

A boolean value that determines if the form fields are
L<sticky|Jifty::Manual::Glossary/sticky> when the action fails.  Defaults to
true.

=item sticky_on_success

A boolean value that determines if the form fields are
L<sticky|Jifty::Manual::Glossary/sticky> when the action succeeds.  Defaults
to false.

=back

=cut

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    my %args = (
        order      => undef,
        arguments  => {},
        sticky_on_success => 0,
        sticky_on_failure => 1,
        @_);

    $self->moniker($args{'moniker'} || 'auto-'.Jifty->web->serial);
    $self->order($args{'order'});
    $self->argument_values( { %{ $args{'arguments'} } } );
    $self->result(Jifty->web->response->result($self->moniker) || Jifty::Result->new);
    $self->result->action_class(ref($self));

    $self->sticky_on_success($args{sticky_on_success});
    $self->sticky_on_failure($args{sticky_on_failure});

    return $self;
}

=head2 arguments

B<Note>: this API is in serious need of rototilling.  Expect it to
change in the near future, into something probably more declarative,
like L<Jifty::DBI::Schema>'s.  This will also increase the speed;
these methods are the most-often called in Jifty, so caching them will
improve things significantly.

This method, along with L</take_action>, is the most commonly
overridden method.  It should return a hash which describes the
L<arguments|Jifty::Manual::Glossary/argument> this action takes:

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
these should have the L<constructor|Jifty::Manual::Glossary/constructor>
property set.  This is separate from the
L<mandatory|Jifty::Manual::Glossary/mandatory> property, which deal with
requiring that the user enter a value for that field.

See L<Jifty::Web::Form::Field> for the list of possible keys that each
argument can have.

=cut

sub arguments {
    my  $self= shift;
    return {}
}

=head2 run

This routine, unsurprisingly, actually runs the action.

If the result of the action is currently a success (validation did not
fail), then calls L</take_action>, and finally L</cleanup>.

=cut

sub run {
    my $self = shift;
    return unless $self->result->success;
    $self->take_action;
    $self->cleanup;
}

=head2 validate


Checks authorization with L</check_authorization>, calls C</setup>,
canonicalizes and validates each argument that was submitted, but
doesn't actually call L</take_action>.

The outcome of all of this is stored on the L</result> of the action.

=cut

sub validate {
    my $self = shift;
    $self->check_authorization || return;
    $self->setup || return;
    $self->_canonicalize_arguments || return;
    $self->_validate_arguments;
}

=head2 check_authorization

Returns true if whoever invoked this action is authorized to perform
this action. 

By default, always returns true.

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

The return value from this method is NOT returned. (Instead, you
should be using the L</result> object to store a result).

=cut

sub take_action { 1; }


=head2 cleanup

Perform any action specific cleanup.  By default, does nothing.

Runs after take_action -- whether or not take_action returns success.

=cut

sub cleanup { 1; }

=head2 moniker

Returns the L<moniker|Jifty::Manual::Glossary/moniker> for this action.

=head2 argument_value ARGUMENT [VALUE]

Returns the value from the argument with the given name, for this
action.  If I<VALUE> is provided, sets the value.

=cut

sub argument_value {
    my $self = shift;
    my $arg = shift;

    $self->argument_values->{$arg} = shift if @_;
    return $self->argument_values->{$arg};
}


=head2 form_field ARGUMENT

Returns a L<Jifty::Web::Form::Field> object for this argument.  If
there is no entry in the L</arguments> hash that matches the given
C<ARGUMENT>, returns C<undef>.

=cut


sub form_field {
    my $self = shift;
    my $arg_name = shift;
    $self->_form_widget( argument => $arg_name,
                         render_mode => 'update',
                         @_);

}


=head2 form_value ARGUMENT

Returns a L<Jifty::Web::Form::Field> object that renders a display
value instead of an editable widget for this argument.  If there is no
entry in the L</arguments> hash that matches the given C<ARGUMENT>,
returns C<undef>.

=cut

sub form_value {
    my $self = shift;
    my $arg_name = shift;
    $self->_form_widget( argument => $arg_name,
                         render_mode => 'read',
                         @_);

}

# Generalized helper for the two above
sub _form_widget {
    my $self       = shift;
    my %args = ( argument => undef,
                 render_mode => 'update',
                 @_);


    my $arg_name = $args{'argument'}. '!!' .$args{'render_mode'};

    if ( not exists $self->{_private_form_fields_hash}{$arg_name} ) {

        my $field_info = $self->arguments->{$args{'argument'}};

        my $sticky = 0;
        $sticky = 1 if $self->sticky_on_failure and (!Jifty->web->response->result($self->moniker) or $self->result->failure);
        $sticky = 1 if $self->sticky_on_success and (Jifty->web->response->result($self->moniker) and $self->result->success);

        if ($field_info) {
            # form_fields overrides stickiness of what the user last entered.
            $self->{_private_form_fields_hash}{$arg_name}
                = Jifty::Web::Form::Field->new(
                action       => $self,
                name         => $args{'argument'},
                sticky       => $sticky,
                sticky_value => $self->argument_value($args{'argument'}),
                render_mode  => $args{'render_mode'},
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

=head2 order [INTEGER]

Gets or sets the order that the action will be run in.  This should be
an integer, with lower numbers being run first.  Defaults to zero.

=head2 result [RESULT]

Returns the L<Jifty::Result> method associated with this action.  If
an action with the same moniker existed in the B<last> request, then
this contains the results of that action.

=head2 register

Registers this action as being present, by outputting a snippet of
HTML.  This expects that an HTML form has already been opened.  Note
that this is not a guarantee that the action will be run, even if the
form is submitted.  See L<Jifty::Request> for the definition of
"L<active|Jifty::Manual::Glossary/active>" actions.

Normally, L<Jifty::Web/new_action> takes care of calling this when it
is needed.

=cut

sub register {
    my $self = shift;
    Jifty->web->out( qq!<input type="hidden"! .
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

=head2 render_errors

Render any the L<Jifty::Result/error> of this action, if any, as HTML.
Returns nothing.

=cut

sub render_errors {
    my $self = shift;
    my $m = Jifty->web->mason; 
    
    if (defined $self->result->error) {
        $m->out('<div class="form_errors">');
        # XXX TODO FIXME escape?
        $m->out('<span class="error">'. $self->result->error .'</span>');
        $m->out('</div>');
    }

    return '';
}

=head2 button arguments => { KEY => VALUE }, PARAMHASH

Create and render a button.  It functions nearly identically like
L<Jifty::Web/link>, except it takes C<arguments> in addition to
C<parameters>, and defaults to submitting this L<Jifty::Action>.
Returns nothing.

=cut

sub button {
    my $self = shift;
    my %args = ( arguments => {},
                 @_);

    $args{parameters}{$self->form_field_name($_)} = $args{arguments}{$_}
      for keys %{$args{arguments}};

    Jifty->web->link(%args,
                     submit => $self,
                    );
}

=head1 NAMING METHODS

These methods return the names of HTML form elements related to this
action.

=head2 register_name

Returns the name of the "registration" query argument for this action
in a web form.

=cut

sub register_name {
    my $self = shift;
    return 'J:A-' . (defined $self->order ? $self->order . "-" : "") .$self->moniker;
}


=head2 form_field_name ARGUMENT

Turn one of this action's L<arguments|Jifty::Manual::Glossary/arguments> into
a fully qualified name; takes the name of the field as an argument.

=cut

sub form_field_name {
    my $self = shift;
    my $field_name = shift;
    return "J:A:F-$field_name-".$self->moniker;
}


=head2 fallback_form_field_name ARGUMENT

Turn one of this action's L<arguments|Jifty::Manual::Glossary/arguments> into
a fully qualified "fallback" name; takes the name of the field as an
argument.

This is specifically to support checkboxes, which only show up in the
query string if they are checked.  Jifty creates a checkbox with the
value of L<form_field_name> as its name and a value of 1, and a hidden
input with the value of L<fallback_form_field_name> as its name and a
value of 0; using this information, L<Jifty::Request> can both
determine if the checkbox was present at all in the form, as well as
its true value.

=cut

sub fallback_form_field_name {
    my $self = shift;
    my $field_name = shift;
    return "J:A:F:F-$field_name-".$self->moniker;
}


=head2 double_fallback_form_field_name ARGUMENT

Turn one of this action's L<arguments|Jifty::Manual::Glossary/arguments> into
a fully qualified "double fallback" name; takes the name of the field
as an argument.

This is specifically to support "constructor" hidden inputs, which
need to be have even lower precedence than checkbox fallbacks.
Probably we need a more flexible system, though.

=cut

sub double_fallback_form_field_name {
    my $self = shift;
    my $field_name = shift;
    return "J:A:F:F:F-$field_name-".$self->moniker;
}


=head2 error_div_id ARGUMENT

Turn one of this action's L<arguments|Jifty::Manual::Glossary/arguments> into
the id for the div in which its errors live; takes name of the field
as an argument.

=cut

sub error_div_id {
  my $self = shift;
  my $field_name = shift;
  return 'errors-' . $self->form_field_name($field_name);
}


=head1 VALIDATION METHODS

=head2 argument_names

Returns the list of argument names.  This information is extracted
from L</arguments>.

=cut

sub argument_names {
    my $self = shift;
    return (keys %{$self->arguments});
}


=head2 _canonicalize_arguments

Canonicalizes each of the L<arguments|Jifty::Manual::Glossary/arguments> that
this action knows about.

This is done by calling L</_canonicalize_argument> for each field
described by L</arguments>.

=cut

# XXX TODO: This is named with an underscore to prevent infinite
# looping with arguments named "argument" or "arguments".  We need a
# better solution.
sub _canonicalize_arguments {
    my $self   = shift;
    my @fields = $self->argument_names;

    my $all_fields_ok = 1;
    foreach my $field (@fields) {
        next unless $field and exists $self->argument_values->{$field};
        unless ( $self->_canonicalize_argument($field) ) {

            $all_fields_ok = 0;
        }
    }
    return $all_fields_ok;
}


=head2 _canonicalize_argument ARGUMENT

Canonicalizes the value of an L<argument|Jifty::Manual::Glossary/argument>.
If the argument has an attribute named B<canonicalizer>, call the
subroutine reference that attribute points points to.

If it doesn't have a B<canonicalizer> attribute, but the action has a
C<canonicalize_I<ARGUMENT>> function, also invoke that function.

=cut

# XXX TODO: This is named with an underscore to prevent infinite
# looping with arguments named "argument" or "arguments".  We need a
# better solution.
sub _canonicalize_argument {
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

=head2 _validate_arguments

Validates the form fields.  This is done by calling
L</_validate_argument> for each field described by L</arguments>

=cut

# XXX TODO: This is named with an underscore to prevent infinite
# looping with arguments named "argument" or "arguments".  We need a
# better solution.
sub _validate_arguments {
    my $self   = shift;
    
    $self->_validate_argument($_)
      for $self->argument_names;

    return $self->result->success;
}

=head2 _validate_argument ARGUMENT

Validate your form fields.  If the field C<ARGUMENT> is mandatory,
checks for a value.  If the field has an attribute named B<validator>,
call the subroutine reference validator points to.

If the action doesn't have an explicit B<validator> attribute, but
does have a C<validate_I<ARGUMENT>> function, invoke that function.

=cut

# XXX TODO: This is named with an underscore to prevent infinite
# looping with arguments named "argument" or "arguments".  We need a
# better solution.
sub _validate_argument {
    my $self  = shift;
    my $field = shift;

    return unless $field;
    my $field_info = $self->arguments->{$field};
    return unless $field_info;

    my $value = $self->argument_value($field);

    if ( !defined $value || !length $value ) {

        if ( $field_info->{mandatory} ) {
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

=head2 _autocomplete_argument ARGUMENT

Get back a list of possible completions for C<ARGUMENT>.

If the field has an attribute named B<autocompleter>, call the
subroutine reference B<autocompleter> points to.

If the action doesn't have an explicit B<autocomplete> attribute, but
does have a C<autocomplete_I<ARGUMENT>> function, invoke that
function.


=cut

# XXX TODO: This is named with an underscore to prevent infinite
# looping with arguments named "argument" or "arguments".  We need a
# better solution.
sub _autocomplete_argument {
    my $self  = shift;
    my $field = shift;
    my $field_info = $self->arguments->{$field};
    my $value = $self->argument_value($field);

    my $default_autocomplete = 'autocomplete_' . $field;

    if ( $field_info->{autocompleter}  )
    {
        return $field_info->{autocompleter}->(  $value );
    }

    elsif ( $self->can($default_autocomplete) ) {
        return $self->$default_autocomplete( $value );
    }

}

=head2 valid_values ARGUMENT

Given an L<argument|Jifty::Manual::Glossary/argument> name, returns the list
of valid values for it, based on its C<valid_values> parameter in the
L</arguments> list.

If the parameter is not an array ref, just returns it (not sure if
this is ever OK except for C<undef>).  If it is an array ref, returns
a new array ref with each element converted into a hash with keys
C<display> and C<value>, which should be (if in a SELECT, say) the
string to display for the value, and the value to actually send to the
server.  Things that are allowed in the array include hashes with
C<display> and C<value> (which are just sent through); hashes with
C<collection> (a L<Jifty::Collection>), and C<display_from> and
C<value_from> (the names of methods to call on each record in the
collection to get C<display> and C<value>); or strings, which are
treated as both C<display> and C<value>.

(Avoid using this -- this is not the appropriate place for this logic
to be!)

=cut

sub valid_values {
    my $self = shift;
    my $field = shift;

    $self->_values_for_field( $field => 'valid' );
}

=head2 available_values ARGUMENT

Just like L<valid_values>, but if our action has a set of available
recommended values, returns that instead. (We use this to
differentiate between a list of acceptable values and a list of
suggested values)

=cut

sub available_values {
    my $self = shift;
    my $field = shift;

    $self->_values_for_field( $field => 'available' ) || $self->_values_for_field( $field => 'valid' );

}

# TODO XXX FIXME this is probably in the wrong place, logically
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

=head2 validation_error ARGUMENT => ERROR TEXT

Used to report an error during validation.  Inside a validator you
should write:

  return $self->validation_error( $field => "error");

..where C<$field> is the name of the argument which is at fault.

=cut

sub validation_error {
    my $self = shift;
    my $field = shift;
    my $error = shift;
  
    $self->result->field_error($field => $error); 
  
    return 0;
}

=head2 validation_ok ARGUMENT

Used to report that a field B<does> validate.  Inside a validator you
should write:

  return $self->validation_ok($field);

=cut

sub validation_ok {
    my $self = shift;
    my $field = shift;

    $self->result->field_error($field => undef);

    return 1;
}

1;
