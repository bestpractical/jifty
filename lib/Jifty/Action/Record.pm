use warnings;
use strict;
use Date::Manip ();
package Jifty::Action::Record;

=head1 NAME

Jifty::Action::Record -- An action tied to a record in the database.

=head1 DESCRIPTION

Represents a web-based action that is a create, update, or delete of a
L<Jifty::Record> object.  This automatically populates the arguments
method of L<Jifty::Action> so that you don't need to bother.  To
actually use this class, you probably want to inherit from one of
L<Jifty::Action::Record::Create>, L<Jifty::Action::Record::Update>, or
L<Jifty::Action::Record::Delete> and override the C<record_class>
method.

=cut

use base qw/Jifty::Action/;

__PACKAGE__->mk_accessors(qw(record _cached_arguments));

=head1 METHODS

=head2 record

Access to the underlying L<Jifty::Record> object for this action is
through the C<record> accessor.

=head2 record_class

This method can either be overridden to return a string specifying the
name of the record class, or the name of the class can be passed to
the constructor.

=cut

sub record_class {
    my $self = shift;
    $self->log->fatal("Jifty::Action::Record must be subclassed to be used");
}


=head2 new PARAMHASH

Construct a new C<Jifty::Action::Record> (as mentioned in
L<Jifty::Action>, this should only be called by C<<
framework->new_action >>.  The C<record> value, if provided in the
PARAMHASH, will be used to load the L</record>; otherwise, the
parimary keys will be loaded from the action's argument values, and
the L</record> loaded from those primary keys.

=cut

sub new {
    my $class = shift;
    my %args = (record => undef,
                @_,
               );
    my $self = $class->SUPER::new(%args);

    my $record_class = $self->record_class;
    Jifty::Util->require($record_class);

    # Set up record
    if (ref $record_class) {
        $self->record($record_class);
        $self->argument_value($_, $self->record->$_) for @{ $self->record->_primary_keys };
    } elsif (ref $args{record} and $args{record}->isa($record_class)) {
        $self->record($args{record});
        $self->argument_value($_, $self->record->$_) for @{ $self->record->_primary_keys };
    } else {
        # We could leave out the explicit current user, but it'd have a slight negative
        # performance implications
        $self->record($record_class->new( current_user => Jifty->web->current_user));
        my %given_pks = ();
        for my $pk (@{ $self->record->_primary_keys }) {
            $given_pks{$pk} = $self->argument_value($pk) if defined $self->argument_value($pk);
        }
        $self->record->load_by_primary_keys(%given_pks) if %given_pks;
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

=cut

sub arguments {
  my $self = shift;

  unless ( $self->_cached_arguments ) {
    my $field_info = {};

    my @fields = $self->possible_fields;

    # we use a while here because we may be modifying the fields on the fly.
    while ( my $field = shift @fields ) {
      my $info = {};
      my $column;
      if ( ref $field ) {
        $column = $field;
        $field  = $column->name;
      }
      else {
        $column = $self->record->column($field);
        my $current_value = $self->record->$field;

# If the current value is actually a pointer to another object, dereference it
        $current_value = $current_value->id
          if ref($current_value)
          and $current_value->isa('Jifty::Record');
        $info->{default_value} = $current_value if $self->record->id;
      }

      if ( defined $column->valid_values && $column->valid_values ) {
        $info->{valid_values} = [ @{ $column->valid_values } ];
        $info->{render_as}    = 'Select';
      }
      elsif ( defined $column->type && $column->type =~ /^bool/i ) {
        $info->{render_as} = 'Checkbox';
      }
      elsif ( defined $column->render_as
        && $column->render_as =~ /^password$/i )
      {
        my $same = sub {
          my ( $self, $value ) = @_;
          if ( $value ne $self->argument_value($field) ) {
            return $self->validation_error( $field
                . '_confirm' =>
                "The passwords you typed didn't match each other." );
          }
          else {
            return $self->validation_ok( $field . '_confirm' );
          }
        };

        $field_info->{ $field . "_confirm" } = {
          render_as => 'Password',
          validator => $same,
          mandatory => 0
        };
      }

      elsif ( defined $column->refers_to ) {
        my $refers_to = $column->refers_to;
        if ( UNIVERSAL::isa($refers_to, 'Jifty::Record') ) {

          my $collection = Jifty::Collection->new(
            record_class => $refers_to,
            current_user => $self->record->current_user
          );
          $collection->unlimit;

          # XXX This assumes a ->name and a ->id method
          $info->{valid_values} = [
            { display_from => $refers_to->can('name') ? "name" : "id",
              value_from   => 'id',
              collection   => $collection
            }
          ];

          $info->{render_as} = 'Select';
        }
      }

      # build up a validator sub if the column implements validation
      # and we're not overriding it at the action level
      my $validate_method = "validate_" . $field;

      if ( ($column->validator ||  $self->record->can($validate_method)) and not $self->can($validate_method)) {
        $info->{ajax_validates} = 1;
        $info->{validator} = sub {
          my $self  = shift;
          my $value = shift;
          my ( $is_valid, $message );
      	if ( $self->record->can($validate_method) ) {
          ($is_valid, $message) =  $self->record->$validate_method($value);
	 } else {
          ( $is_valid, $message ) = &{ $column->validator }( $self->record, $value );
	}
          if ($is_valid) {
            return $self->validation_ok($field);
          }
          else {
            unless ($message) {
              $self->log->error(
                qq{Schema validator for $field didn't explain why the value '$value' is invalid}
              );
            }
            return (
              $self->validation_error(
                $field => $message
                  || q{That doesn't look right, but I don't know why}
              )
            );
          }
        };
      }
      my $autocomplete_method = "autocomplete_" . $field;
      if ( $self->record->can($autocomplete_method) ) {
        $info->{'autocompleter'} ||= sub {
          my ( $self, $value ) = @_;
          my %columns;
          $columns{$_} = $self->argument_value($_) for grep {$_ ne $field} $self->possible_fields;
          return $self->record->$autocomplete_method($value, %columns);
        };
      }

      my $canonicalize_method = "canonicalize_" . $field;
      if ( $self->record->can($canonicalize_method) ) {
        $info->{'ajax_canonicalizes'} = 1;
        $info->{'canonicalizer'} ||= sub {
          my ( $self, $value ) = @_;
          return $self->record->$canonicalize_method($value);
        };
      }
      elsif ( defined $column->render_as
        and $column->render_as eq "Date" )
      {
        $info->{'ajax_canonicalizes'} = 1;
        $info->{'canonicalizer'} ||= sub {
          my ( $self, $value ) = @_;
          return _canonicalize_date( $self, $value );
        };
      }

      # If we're hand-coding a render_as, hints or label, let's use it.
      for (qw(render_as label hints length mandatory sort_order)) {

        if ( defined $column->$_ ) {
          $info->{$_} = $column->$_;
        }
      }
      $field_info->{$field} = $info;
    }

    $self->_cached_arguments($field_info);
  }
  return $self->_cached_arguments();
}

=head2 possible_fields

Returns the list of fields on the object that the action can update.
This defaults to only the writable fields of the object.

=cut

sub possible_fields {
    my $self = shift;
    return $self->record->writable_attributes;
}

=head2 _canonicalize_date DATE

Parses and returns the date using L<Time::ParseDate>.

=cut

sub _canonicalize_date {
    my $self = shift;
    my $val = shift;
    return undef unless defined $val and $val =~ /\S/;
    return undef unless my $obj = Jifty::DateTime->new_from_string($val);
    return $obj->ymd;
}

=head2 take_action

Throws an error unless it is overridden; use
Jifty::Action::Record::Create, ::Update, or ::Delete

=cut

sub take_action {
    my $self = shift;
    $self->log->fatal("Use one of the Jifty::Action::Record subclasses, ::Create, ::Update or ::Delete");
}


=head1 SEE ALSO

L<Jifty::Action>, L<Jifty::Record>, L<Jifty::DBI::Record>,
L<Jifty::Action::Record::Create>, L<Jifty::Action::Record::Update>

=cut

1;
