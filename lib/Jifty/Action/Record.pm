use warnings;
use strict;

package Jifty::Action::Record;

=head1 NAME

Jifty::Action::Record -- An action tied to a record in the database.

=head1 DESCRIPTION

Represents a web-based action that is a create, update, or delete of a
L<Jifty::Record> object.  This automatically populates the arguments
method of L<Jifty::Action> so that you don't need to bother.  

To actually use this class, you probably want to inherit from one of
L<Jifty::Action::Record::Create>, L<Jifty::Action::Record::Update>, or
L<Jifty::Action::Record::Delete>.  You may need to override the
L</record_class> method, if Jifty cannot determine the record class of
this action.

=cut

use base qw/Jifty::Action/;
use Scalar::Defer qw/ defer /;
use Scalar::Util qw/ blessed /;
use Clone qw/clone/;

__PACKAGE__->mk_accessors(qw(record _cached_arguments));

use constant report_detailed_messages => 1;

our $ARGUMENT_PROTOTYPE_CACHE = {};

=head1 METHODS

=head2 record

Access to the underlying L<Jifty::Record> object for this action is
through the C<record> accessor.

=head2 record_class

This method can either be overridden to return a string specifying the
name of the record class, or the name of the class can be passed to
the constructor.

=head2 report_detailed_messages

If the action returns true for C<report_detailed_message>, report the
message returned by the model classes as the resulting message.  For
Update actions, Put the per-field message in C<detailed_messages>
field of action result content.  The default is false.

=cut

sub record_class {
    my $self = shift;
    return $self->{record_class} ||= do {
        my $class = ref($self);
        my $model;
        if ($class =~ /::(Create|Search|Execute|Update|Delete)([^:]+)$/) {
            $model = Jifty->app_class( Model => $2 );
            undef $model unless grep {$_ eq $model} Jifty->class_loader->models;
        }

        if ($class eq "Jifty::Action::Record") {
            $self->log->fatal("Jifty::Action::Record must be subclassed to be used");
        } elsif (not $model) {
            $self->log->fatal("Cannot determine model for Jifty::Action::Record subclass $class");
        }
        $model
    };
}

=head2 new PARAMHASH

Construct a new C<Jifty::Action::Record> (as mentioned in
L<Jifty::Action>, this should only be called by C<<
framework->new_action >>.  The C<record> value, if provided in the
PARAMHASH, will be used to load the L</record>; otherwise, the
primary keys will be loaded from the action's argument values, and
the L</record> loaded from those primary keys.

=cut

sub new {
    my $class = shift;
    my %args  = (
        record => undef,
        @_,
    );

    my $self = $class->SUPER::new(%args);

    # Look up the record class
    my $record_class = $self->record_class;

    # Die if we were given a record that wasn't a record
    if (ref $args{'record'} && !$args{'record'}->isa($record_class)) {
        Carp::confess($args{'record'}." isn't a $record_class");
    }

    # If the record class is a record, use that
    if ( ref $record_class ) {
        $self->record($record_class);
        $self->argument_value( $_, $self->record->$_ )
            for @{ $self->record->_primary_keys };
    } 

    # Otherwise, try to use the record passed to the constructor
    elsif ( ref $args{record} and $args{record}->isa($record_class) ) {
        $self->record( $args{record} );
        $self->argument_value( $_, $self->record->$_ )
            for @{ $self->record->_primary_keys };
    } 
    
    # Otherwise, try to use the arguments to load the record
    else {
        # We could leave out the explicit current user, but it'd have
        # a slight negative performance implications
        $self->record( $record_class->new( current_user => $self->current_user ) );
        my %given_pks = ();
        for my $pk ( @{ $self->record->_primary_keys } ) {
            $given_pks{$pk} = $self->argument_value($pk)
                if defined $self->argument_value($pk) && ($self->argument_value($pk) ne '');
        }
        $self->record->load_by_primary_keys(%given_pks) if keys %given_pks;
    }

    return $self;
}

=head2 arguments

Overrides the L<Jifty::Action/arguments> method, to automatically
provide a form field for every writable attribute of the underlying
L</record>.

This also creates built-in validation and autocompletion methods
(validate_$fieldname and autocomplete_$fieldname) for action fields
that are defined "validate" or "autocomplete". These methods can
be overridden in any Action which inherits from this class.

Additionally, if our model class defines canonicalize_, validate_, or
autocomplete_ FIELD, generate appropriate an appropriate
canonicalizer, validator, or autocompleter that will call that method
with the value to be validated, canonicalized, or autocompleted.

C<validate_FIELD> should return a (success boolean, message) list.

C<autocomplete_FIELD> should return a the same kind of list as
L<Jifty::Action::_autocomplete_argument|Jifty::Action/_autocomplete_argument>

C<canonicalized_FIELD> should return the canonicalized value.

=cut

sub arguments {
    my $self = shift;

    # Don't do this twice, it's too expensive
    unless ( $self->_cached_arguments ) {
        $ARGUMENT_PROTOTYPE_CACHE->{ ref($self) }
            ||= $self->_build_class_arguments();
        $self->_cached_arguments( $self->_fill_in_argument_record_data() );
    }
    return $self->_cached_arguments();
}

sub _fill_in_argument_record_data {
    my $self = shift;

    my $arguments = clone( $ARGUMENT_PROTOTYPE_CACHE->{ ref($self) } );
    return $arguments unless ( $self->record->id );

    for my $field ( keys %$arguments ) {
        if ( my $function = $self->record->can($field) ) {
            my $weakself = $self;
            Scalar::Util::weaken $weakself;
            $arguments->{$field}->{default_value} = defer {
                my $val = $function->( $weakself->record );

                # If the current value is actually a pointer to
                # another object, turn it into an ID
                return $val->id
                    if ( blessed($val) and $val->isa('Jifty::Record') );
                return $val;
            }
        }

        # The record's current value becomes the widget's default value
    }
    return $arguments;
}

sub _build_class_arguments {
    my $self = shift;

    # Get ready to rumble
    my $field_info = {};
    my @columns    = $self->possible_columns;

    # we use a while here because we may be modifying the fields on the fly.
    while ( my $column = shift @columns ) {
        my $info  = {};
        my $field = $column->name;

        # Canonicalize the render_as setting for the column
        my $render_as = lc( $column->render_as || '' );

        # Use a select box if we have a list of valid values
        if ( defined( my $valid_values = $column->valid_values ) ) {
            $info->{valid_values} = $valid_values;
            $info->{render_as}    = 'Select';
        }

        # Use a checkbox for boolean fields
        elsif ( defined $column->type && $column->type =~ /^bool/i ) {
            $info->{render_as} = 'Checkbox';
        }

        # Add an additional _confirm field for passwords
        elsif ( $render_as eq 'password' ) {

            # Add a validator to make sure both fields match
            my $same = sub {
                my ( $self, $value ) = @_;
                if ( $value ne $self->argument_value($field) ) {
                    return $self->validation_error(
                        ( $field . '_confirm' ) => _(
                            "The passwords you typed didn't match each other")
                    );
                } else {
                    return $self->validation_ok( $field . '_confirm' );
                }
            };

            # Add the extra confirmation field
            $field_info->{ $field . "_confirm" } = {
                render_as  => 'Password',
                virtual    => '1',
                validator  => $same,
                sort_order => ( $column->sort_order + .01 ),
                mandatory  => 0
            };
        }

        # Handle the X-to-one references
        elsif ( defined( my $refers_to = $column->refers_to ) ) {

            # Render as a select box unless they override
            if ( UNIVERSAL::isa( $refers_to, 'Jifty::Record' ) ) {
                $info->{render_as} = $render_as || 'Select';

                $info->{render_as} = 'Text'
                    unless $column->refers_to->enumerable;
            }

            # If it's a select box, setup the available values
            if ( UNIVERSAL::isa( $refers_to, 'Jifty::Record' )
                && $info->{render_as} eq 'Select' )
            {
                $info->{'valid_values'}
                    = $self->_default_valid_values( $column, $refers_to );
            }

            # If the reference is X-to-many instead, skip it
            else {

                # No need to generate arguments for
                # JDBI::Collections, as we can't do anything
                # useful with them yet, anyways.

                # However, if the column comes with a
                # "render_as", we can assume that the app
                # developer know what he/she is doing.
                # So we just render it as whatever specified.

# XXX TODO -  the next line seems to be a "next" which meeant to just fall through the else
# next unless $render_as;
            }
        }

        #########

        $info->{'autocompleter'} ||= $self->_argument_autocompleter($column);
        my ( $validator, $ajax_validates )
            = $self->_argument_validator($column);
        $info->{validator}      ||= $validator;
        $info->{ajax_validates} ||= $ajax_validates;
        my ( $canonicalizer, $ajax_canonicalizes )
            = $self->_argument_canonicalizer($column);
        $info->{'canonicalizer'}      ||= $canonicalizer;
        $info->{'ajax_canonicalizes'} ||= $ajax_canonicalizes;

        # If we're hand-coding a render_as, hints or label, let's use it.
        for (
            qw(render_as label hints display_length max_length mandatory sort_order container documentation attributes)
            )
        {
            if ( defined( my $val = $column->$_ ) ) {
                $info->{$_} = $val;
            }
        }

        $field_info->{$field} = $info;
    }

    # After all that, use the schema { ... } params for the final bits
    if ( $self->can('PARAMS') ) {

       # User-defined declarative schema fields can override default ones here
        my $params = $self->PARAMS;

     # We really, really want our sort_order to prevail over user-defined ones
     # (as opposed to all other param fields).  So we do exactly that here.
        while ( my ( $key, $param ) = each %$params ) {
            defined( my $sort_order = $param->sort_order ) or next;

        # The .99 below means that it's autogenerated by Jifty::Param::Schema.
            if ( $sort_order =~ /\.99$/ ) {
                $param->sort_order( $field_info->{$key}{sort_order} );
            }
        }

        # Cache the result of merging the Jifty::Action::Record and schema
        # parameters
        use Jifty::Param::Schema ();
        return Jifty::Param::Schema::merge_params( $field_info, $params );
    }

    # No schema { ... } block, so just use what we generated
    else {
        return $field_info;
    }
}

sub _argument_validator {
    my $self    = shift;
    my $column  = shift;
    my $field   = $column->name;
    my $do_ajax = $column->attributes->{ajax_validates};
    my $method;

    # Figure out what the action's validation method would for this field
    my $validate_method = "validate_" . $field;

    # Build up a validator sub if the column implements validation
    # and we're not overriding it at the action level
    if ( $column->validator and not $self->can($validate_method) ) {
        $do_ajax = 1;
        $method  = sub {
            my $self  = shift;
            my $value = shift;

            # Check the column's validator
            my ( $is_valid, $message )
                = &{ $column->validator }( $self->record, $value, @_ );

            # The validator reported valid, return OK
            return $self->validation_ok($field) if ($is_valid);

            # Bad stuff, report an error
            unless ($message) {
                $self->log->error(
                    qq{Schema validator for $field didn't explain why the value '$value' is invalid}
                );
            }
            return (
                $self->validation_error(
                    $field => (
                        $message || _(
                            "That doesn't look right, but I don't know why")
                    )
                )
            );
            }
    }

    return ( $method, $do_ajax );
}

sub _argument_canonicalizer {
    my $self    = shift;
    my $column  = shift;
    my $field   = $column->name;
    my $do_ajax = $column->attributes->{ajax_canonicalizes};
    my $method;

    # Add a canonicalizer for the column if the record provides one
    if ( $self->record->has_canonicalizer_for_column($field) ) {
        $do_ajax = 1 unless defined $column->render_as and lc( $column->render_as ) eq 'checkbox';
        my $for = $self->isa('Jifty::Action::Record::Create') ? 'create' : 'update';
        $method ||= sub {
            my ( $self, $value ) = @_;
            return $self->record->run_canonicalization_for_column(
                column => $field,
                value  => $value,
                extra  => [$self->argument_values, { for => $for }],
            );
        };
    }

    # Otherwise, if it's a date, we have a built-in canonicalizer for that
    elsif ( defined $column->render_as and lc( $column->render_as ) eq 'date' ) {
        $do_ajax = 1;
    }
    return ( $method, $do_ajax );
}

sub _argument_autocompleter {
    my $self   = shift;
    my $column = shift;
    my $field  = $column->name;

    my $autocomplete;

    # What would the autocomplete method be for this column in the record
    my $autocomplete_method = "autocomplete_" . $field;

    # Set the autocompleter if the record has one
    if ( $self->record->can($autocomplete_method) ) {
        $autocomplete ||= sub {
            my ( $self, $value ) = @_;
            my %columns;
            $columns{$_} = $self->argument_value($_)
                for grep { $_ ne $field } $self->possible_fields;
            return $self->record->$autocomplete_method( $value, %columns );
        };
    }

    # The column requests an automagically generated autocompleter, which
    # is baed upon the values available in the field
    elsif ( $column->autocompleted ) {

        # Auto-generated autocompleter
        $autocomplete
            ||= sub { $self->_default_autocompleter( shift, $field ) };

    }
    return $autocomplete;
}

sub _default_valid_values {
    my $self      = shift;
    my $column    = shift;
    my $refers_to = shift;

    my @valid;

    # Get an unlimited collection
    my $collection = Jifty::Collection->new(
        record_class => $refers_to,
        current_user => $self->record->current_user,
    );
    $collection->find_all_rows;

    # Fetch the _brief_description() method
    my $method = $refers_to->_brief_description();

    # FIXME: we should get value_from with the actualy refered by key

    # Setup the list of valid values
    @valid = (
        {   display_from => $refers_to->can($method) ? $method : "id",
            value_from   => 'id',
            collection   => $collection
        }
    );
    unshift @valid,
        {
        display => _('no value'),
        value   => ''
        }
        unless $column->mandatory;
    return \@valid;

}

sub _default_autocompleter {
    my ( $self, $value, $field ) = @_;

    my $collection = Jifty::Collection->new(
        record_class => $self->record_class,
        current_user => $self->record->current_user
    );

    # Return the first 20 matches...
    $collection->rows_per_page(20);

    # ...that start with the value typed...
    if ( length $value ) {
        $collection->limit(
            column           => $field,
            value            => $value,
            operator         => 'STARTSWITH',
            entry_aggregator => 'AND'
        );
    }

    # ...but are not NULL...
    $collection->limit(
        column           => $field,
        value            => 'NULL',
        operator         => 'IS NOT',
        entry_aggregator => 'AND'
    );

    # ...and are not empty.
    $collection->limit(
        column           => $field,
        value            => '',
        operator         => '!=',
        entry_aggregator => 'AND'
    );

    # Optimize the query a little bit
    $collection->columns( 'id', $field );
    $collection->order_by( column => $field );
    $collection->group_by( column => $field );

    # Set up the list of choices to return
    my @choices;
    while ( my $record = $collection->next ) {
        push @choices, $record->$field;
    }
    return @choices;
}

=head2 possible_columns

Returns the list of columns objects on the object that the action
can update. This defaults to all of the C<containers> or the non-C<private>,
non-C<virtual> and non-C<serial> columns of the object.

=cut

sub possible_columns {
    my $self = shift;
    return grep {
        $_->container
            or ( !$_->private and !$_->virtual and !$_->computed and $_->type ne "serial" )
    } $self->record->columns;
}

=head2 possible_fields

Returns the list of the L</possible_columns>' names.

Usually at the end names are required, however for subclassing column objects
are better, or this method in a subclass turns out to be "map to column" -
"filter" - "map to name" chain.

=cut

sub possible_fields {
    my $self = shift;
    return map { $_->name } $self->possible_columns;
}

=head2 take_action

Throws an error unless it is overridden; use
Jifty::Action::Record::Create, ::Update, or ::Delete

=cut

sub take_action {
    my $self = shift;
    $self->log->fatal(
        "Use one of the Jifty::Action::Record subclasses, ::Create, ::Update or ::Delete or ::Search"
    );
}

sub _setup_event_before_action {
    my $self = shift;

    # Setup the information regarding the event for later publishing
    my $event_info = {};
    $event_info->{as_hash_before} = $self->record->as_hash;
    $event_info->{record_id}      = $self->record->id;
    $event_info->{record_class}   = ref( $self->record );
    $event_info->{action_class}   = ref($self);
    $event_info->{action_arguments}
        = $self->argument_values;    # XXX does this work?
    $event_info->{current_user_id} = $self->current_user->id || 0;
    return ($event_info);
}

sub _setup_event_after_action {
    my $self       = shift;
    my $event_info = shift;

    unless ( defined $event_info->{record_id} ) {
        $event_info->{record_id}    = $self->record->id;
        $event_info->{record_class} = ref( $self->record );
        $event_info->{action_class} = ref($self);
    }

    # Add a few more bits about the result
    $event_info->{result}        = $self->result;
    $event_info->{timestamp}     = time();
    $event_info->{as_hash_after} = $self->record->as_hash;

    # Publish the event
    my $event_class = $event_info->{'record_class'};
    $event_class =~ s/::Model::/::Event::Model::/g;
    Jifty::Util->require($event_class);
    $event_class->new($event_info)->publish;
}

=head1 SEE ALSO

L<Jifty::Action>, L<Jifty::Record>, L<Jifty::DBI::Record>,
L<Jifty::Action::Record::Create>, L<Jifty::Action::Record::Update>,
L<Jifty::Action::Record::Delete>

=head1 LICENSE

Jifty is Copyright 2005-2010 Best Practical Solutions, LLC.
Jifty is distributed under the same terms as Perl itself.

=cut

1;
