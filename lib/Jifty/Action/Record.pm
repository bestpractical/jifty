use warnings;
use strict;
use Time::ParseDate ();
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

__PACKAGE__->mk_accessors(qw(record));

=head1 METHODS

=head2 record

Access to the underlying Jifty::Record object that this action is
through the C<record> accessor.

=cut


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

Construct a new C<Jifty::Action::Record> (should only be called by C<<
framework->new_action >>.  The C<record> value, if provided in the
PARAMHASH, will be used to load the record; otherwise, the parimary
keys will be loaded from the action's argument values.

=cut

sub new {
    my $class = shift;
    my %args = (record => undef,
                @_,
               );
    my $self = $class->SUPER::new(%args);

    my $record_class = $self->record_class;
    $record_class->require;

    $self->log->error("Can't require $record_class") if $UNIVERSAL::require::ERROR;

    # Set up record
    if (ref $record_class) {
        $self->record($record_class);
        $self->argument_value($_, $self->record->$_) for @{ $self->record->_primary_keys };
    } elsif (UNIVERSAL::isa($args{record}, $record_class)) {
        $self->record($args{record});
        $self->argument_value($_, $self->record->$_) for @{ $self->record->_primary_keys };
    } else {
        # We could leave out the explicit current user, but it'd have a slight negative
        # performance implications
        $self->record($record_class->new( current_user => Jifty->framework->current_user));
        my %given_pks = ();
        for my $pk (@{ $self->record->_primary_keys }) {
            $given_pks{$pk} = $self->argument_value($pk) if defined $self->argument_value($pk);
        }
        $self->record->load_by_primary_keys(%given_pks) if %given_pks;
    }

    return $self;
}


=head2 arguments

Overrides Jifty::Action's arguments method, to automatically
provide a form field for every writable attribute of the underlying
record.

=cut

# XXX TODO  should this be memoized?
sub arguments {
    my $self = shift;

    my $field_info = {};

    my @fields = $self->record->writable_attributes;

    # we use a while here because we may be modifying the fields on the fly.
    while ( my $field = shift @fields ) {
        my $info = {};
        my $column;
        if (ref $field) {
            $column = $field;
            $field = $column->name;
        } else {
            $column = $self->record->column($field);
            my $current_value = $self->record->$field;

            # If the current value is actually a pointer to another object, dereference it
            $current_value = $current_value->id
              if UNIVERSAL::isa( $current_value, 'Jifty::Record' );
            $info->{default_value} = $current_value if $self->record->id;
        }

        if ( defined $column->valid_values && $column->valid_values ) {
            $info->{valid_values} = [ @{$column->valid_values } ];
            $info->{render_as}    = 'Select';
        }
        elsif ( defined $column->type && $column->type =~ /^bool/i ) {
            $info->{render_as} = 'Checkbox';
        }
        elsif ($column->name !~ /_confirm$/i
                && defined $column->render_as 
                && $column->render_as =~ /^password$/i) {
            unshift @fields, Jifty::DBI::Column->new({name => $field . "_confirm", render_as => 'Password', type => 'Password'});
        }

        elsif ( defined $column->refers_to ) {
            my $ref = $column->refers_to;
            if ( UNIVERSAL::isa( $ref, 'Jifty::Record' ) ) {

                my $collection = Jifty::Collection->new(
                    record_class => $ref,
                    current_user => $self->record->current_user
                );
                $collection->unlimit;

                # XXX This assumes a ->name and a ->id method
                $info->{valid_values} = [
                    {   display_from => 'name',
                        value_from   => 'id',
                        collection   => $collection
                    }
                ];

                $info->{render_as} = 'Select';
            }
        }

        # build up a validator sub if the column implements validation
        if ( defined $column->validator && $column->validator ) {
            $info->{ajax_validates} = 1;
            $info->{validator} = sub {
                my $self  = shift;
                my $value = shift;
                my ( $is_valid, $message )
                    = &{ $column->validator }( $self->record, $value );
                if ($is_valid) {
                    return $self->validation_ok($field);
                }
                else {
                    unless ($message) {
                        $self->log->error(
                            qq{_Schema validator for $field didn't explain why the value '$value' is invalid}
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
   
        my $autocomplete_method = "autocomplete_".$field;
        if ($self->record->can($autocomplete_method) ) {
            $info->{'ajax_autocomplete'} = 1;
            $info->{'autocomplete_coderef'} = sub { 
                    my $value = shift;
                    return $self->record->$autocomplete_method( $value);
                };
        }


        # If we're hand-coding a render_as, hints or label, let's use it.
        for ( qw(render_as label hints length)) { 
        
            if ( defined $column->$_ and not $info->{$_}) {
                 $info->{$_} = $column->$_;
            }
        }
        $field_info->{$field} = $info;
    }

    return $field_info;
}


=head2 canonicalize_argument ARGUMENT_NAME

Canonicalizes the argument named ARGUMENT_NAME. This routine actually just makes sure 
we can canonicalize dates and then passes on to the superclass.

=cut


sub canonicalize_argument {
    my $self = shift;
    my $arg_name = shift;


    if (exists $self->arguments->{$arg_name}->{'render_as'} 
     and $self->arguments->{$arg_name}->{'render_as'} eq 'Date') {
        my $value = $self->canonicalize_date($self->argument_value($arg_name));
        $self->argument_value($arg_name => $value);
    }

    return($self->SUPER::canonicalize_argument($arg_name));

}

=head2 canonicalize_date

Parses the date using L<Time::ParseDate>.

=cut

sub canonicalize_date {
    my $self = shift;
    my $val = shift;
    return undef unless defined $val and $val =~ /\S/;
    my $epoch =  Time::ParseDate::parsedate($val, FUZZY => 1, PREFER_FUTURE => 1, GMT =>0) || '';
    return undef unless $epoch;
    my $dt  = DateTime->from_epoch( epoch =>$epoch, time_zone => 'local');
    return $dt->ymd;
}

=head2 take_action

Throws an error unless it is overridden; use
Jifty::Action::Record::Update, ::Delete, or ::Create

=cut

sub take_action {
    my $self = shift;
    $self->log->fatal("Use one of the Jifty::Action::Record subclasses, ::Update or ::Create");
}


=head1 SEE ALSO

L<Jifty::Action>, L<Jifty::Record>, L<Jifty::DBI::Record>,
L<Jifty::Action::Record::Create>, L<Jifty::Action::Record::Update>

=cut

1;
