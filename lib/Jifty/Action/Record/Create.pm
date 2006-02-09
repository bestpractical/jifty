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

=head1 METHODS

=head2 arguments

Set the default value in each of the fields to whatever the default of
the column is in the model

=cut

sub arguments {
    my $self = shift;
    
    my $args = $self->SUPER::arguments;
    for my $arg (keys %{$args}) {
        next unless $self->record->column($arg);
        $args->{$arg}{default_value} = $self->record->column($arg)->default
          if not $args->{$arg}->{default_value};
    }
    return $args;
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

    my %values;
    $values{$_} = $self->argument_value($_) for grep { defined $self->argument_value($_) } $self->argument_names;
    
    my ($id) = $record->create(%values);

    # Handle errors?
    unless ( $record->id ) {
        $self->result->error("An error occurred.  Try again later");
        $self->log->error("Create of ".ref($record)." failed: ", $id);
        return;
    }

 
    # Return the id that we created
    $self->result->content(id => $self->record->id);
    $self->report_success if  not $self->result->failure;

    return 1;
}

=head2 report_success

Sets the L<Jifty::Result/message> to default success message,
"Created". Override this if you want to report some other
more user-friendly result.

=cut

sub report_success {
    my $self = shift;
    $self->result->message("Created")
}


1;
