use warnings;
use strict;

package Jifty::Action::Record::Create;

=head1 NAME

Jifty::Action::Record::Create - Automagic creation action

=head1 DESCRIPTION

This class is used as the base class for L<Jifty::Action>s that are
merely creating L<Jifty::Record> objects.  To use it, subclass it and
override the C<record_class> method to return the name of the
L<Jifty::Record> subclass that this action creates.

=cut

use base qw/Jifty::Action::Record/;

use Hash::Merge;

=head1 METHODS

=head2 arguments

Set the default value in each of the fields to whatever the default of
the column is in the model

=cut

sub arguments {
    my $self = shift;

    # Add default values to the arguments configured by Jifty::Action::Record
    my $args = $self->SUPER::arguments;
    for my $arg ( keys %{$args} ) {
        unless ( $args->{$arg}->{default_value} ) {
            my $column = $self->record->column($arg);
            next if not $column;
            $args->{$arg}{default_value} = $column->default;
        }
    }
   
    if ( $self->can('PARAMS') ) {
        use Jifty::Param::Schema;
        return Jifty::Param::Schema::merge_params(
            $args, ($self->PARAMS || {})
        );
    }
    else {
        return $args;
    }
}

=head2 take_action

Overrides the virtual C<take_action> method on L<Jifty::Action> to call
the appropriate C<Jifty::Record>'s C<create> method when the action is
run, thus creating a new object in the database.

The C<id> of the new row is returned in the C<id> content of the
L<Jifty::Result> for the action.  You can use this in conjunction with
L<request mapping|Jifty::Request::Mapper> in order to give later parts
of the request access to the C<id>.

=cut

sub take_action {
    my $self   = shift;
    my $record = $self->record;

    # Build the event to be fired later
    my $event_info = $self->_setup_event_before_action();
    
    my %values;

    # Iterate through all that are set, except for the virtual ones
    for (grep { defined $self->argument_value($_) && !$self->arguments->{$_}->{virtual} } $self->argument_names) {

        # Prepare the hash to pass to create for each argument
        $values{$_} = $self->argument_value($_);
    }

    # Attempt creating the record
    my $id;
    my $msg = $self->create_record(%values);

    # Convert Class::ReturnValue to an id and message
    if (ref($msg)) {
        ($id,$msg) = $msg->as_array;
    }

    # If ID is 0/undef, the record didn't create, so we fail
    if (! $record->id ) {
        $self->log->warn(_("Create of %1 failed: %2", ref($record), $msg));
        $self->result->error($msg || _("An error occurred.  Try again later"));
    }

    # No errors! Report success
    else { 
        # Return the id that we created
        $self->result->content(id => $self->record->id);
        $self->report_success if  not $self->result->failure;
    }

    # Publish the event, noting success or failure
    $self->_setup_event_after_action($event_info);

    return ($self->record->id);
}

=head2 create_record

This method actually performs the call to C<< record->create >>. It receives as
arguments the parameter hash and should return the message for the user,
indicating success or failure.

=cut

sub create_record {
    my $self = shift;
    my $record = $self->record;

    return $record->create(@_);
}

=head2 report_success

Sets the L<Jifty::Result/message> to default success message,
"Created". Override this if you want to report some other
more user-friendly result.

=cut

sub report_success {
    my $self = shift;
    $self->result->message(_("Created"))
}

=head2 possible_columns

Create actions do not provide fields for columns marked as C<private>
or C<protected>.

=cut

sub possible_columns {
    my $self = shift;
    return grep {not $_->protected} $self->SUPER::possible_columns( @_ );
}

=head2 _extra_validator_args

Passes C<< for => 'create' >> to validators.

=cut

sub _extra_validator_args {
    return { for => 'create' };
}

=head2 _extra_canonicalizer_args

Passes C<< for => 'create' >> to canonicalizers.

=cut

sub _extra_canonicalizer_args {
    return { for => 'create' };
}

=head2 _extra_autocompleter_args

Passes C<< for => 'create' >> to autocompleters.

=cut

sub _extra_autocompleter_args {
    return { for => 'create' };
}

=head1 SEE ALSO

L<Jifty::Action::Record>, L<Jifty::Record>

=head1 LICENSE

Jifty is Copyright 2005-2007 Best Practical Solutions, LLC.
Jifty is distributed under the same terms as Perl itself.

=cut

1;
