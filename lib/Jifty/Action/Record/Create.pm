use warnings;
use strict;

package JFDI::Action::Record::Create;

=head1 NAME

JFDI::Action::Record::Create - Automagic creation action

=head1 DESCRIPTION

This class is used as the base class for L<JFDI::Action>s that are
merely creating JFDI::Record objects.  To use it, subclass it and
override the C<record_class> method to return the name of the
JFDI::Record subclass that this action creates.

=cut

use base qw/JFDI::Action::Record/;

=head1 METHODS

=head2 arguments

Set the default value in each of the fields to whatever the default of
the column is in the model

=cut

sub arguments {
    my $self = shift;
    
    my $args = $self->SUPER::arguments;
    for my $arg (keys %{$args}) {
        $args->{$arg}{default_value} = $self->record->column($arg)->default if not $args->{$arg}->{default_value};
    }
    return $args;
}

=head2 take_action

Overrides the virtual C<take_action> method on L<JFDI::Action> to call
the appropriate C<JFDI::Record>'s C<create> method when the action is
run, thus creating a new object in the database.

=cut

sub take_action {
    my $self   = shift;
    my $record = $self->record;

    my %values;
    $values{$_} = $self->argument_value($_)
      for grep { defined $self->argument_value($_) } $self->argument_names;
    
    my ($id) = $record->create(%values);

    # Handle errors?
    unless ( $record->id ) {
        $self->result->error("An error occurred.  Try again later");
        $self->log->error("Create of ".ref($record)." failed: ", $id);
        return;
    }

   
    $self->report_success if  not $self->result->failure;


    return 1;
}

=head2 report_success

Sets self->result->message to a default success message. Override this if you want
to report some other happy-friendly result


=cut

sub report_success {
    my $self = shift;
    $self->result->message("Created")
}


1;
