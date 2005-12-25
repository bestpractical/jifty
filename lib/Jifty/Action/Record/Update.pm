use warnings;
use strict;

package Jifty::Action::Record::Update;

=head1 NAME

Jifty::Action::Record::Update - automagic update action

=head1 DESCRIPTION

This class is used as the base class for L<Jifty::Action>s that are
merely updating Jifty::Record objects.  To use it, subclass it and
override the C<record_class> method to return the name of the
Jifty::Record subclass that this action should update.

=cut

use base qw/Jifty::Action::Record/;

=head1 METHODS

=head2 arguments

Overrides L<Jifty::Action::Record>'s C<arguments> method to further
specify that all of the primary keys *must* have values when
submitted; that is, they are "constructors."  See
L<Jifty::Action/arguments> for the distinction between "constructor"
and "mandatory."

=cut

sub arguments {
    my $self = shift;
    my $arguments = $self->SUPER::arguments(@_);

    for my $pk (@{ $self->record->_primary_keys }) {
        $arguments->{$pk}{'constructor'} = 1;
        # XXX TODO IS THERE A BETTER WAY TO NOT RENDER AN ITEM IN arguments
        $arguments->{$pk}{'render_as'} = 'Unrendered'; 
        # primary key fields should always be hidden fields
    }
    $arguments->{delete} = {render_as => "Unrendered"};
    return $arguments;
}

=head2 take_action

Overrides the virtual C<take_action> method on L<Jifty::Action> to call
the appropriate C<Jifty::Record>'s C<Set> methods when the action is
run, thus updating the object in the database.

=cut

sub take_action {
    my $self = shift;
    my $changed = 0;

    for my $field ( $self->argument_names ) {

        # Skip values that weren't submitted
        next unless exists $self->argument_values->{$field};

        my $column = $self->record->column($field);

        # Skip nonexistent fields
        next unless $column;

        # Boolean and integer fields should be skipped if blank.
        # (This logic should be moved into SB or something.)
        next
            if ( defined $column->type
            and
            ( $column->type =~ /^bool/i || $column->type =~ /^int/i )
            && $self->argument_value($field) eq '' );

        # Skip fields that have not changed
        my $old = $self->record->$field;
        $old = $old->id if UNIVERSAL::isa( $old, "Jifty::Record" );

        next if ( defined $old and defined $self->argument_value($field) and $old eq $self->argument_value($field) );
        next if ( not $old and not $self->argument_value($field) );

        my $setter = "set_$field";
        my ( $val, $msg )
            = $self->record->$setter( $self->argument_value($field) );
        $self->result->field_error($field, $msg)
          if not $val and $msg;

        $changed = 1 if $val;
    }

    # Remove the record
    if ($self->argument_value("delete")) {
        my ( $val, $msg ) = $self->record->delete;
        $self->result->error($msg)
          if not $val and $msg;

        $changed = 1 if $val;
    }

    $self->report_success
      if $changed and not $self->result->failure;

    return 1;
}

=head2 report_success

Sets self->result->message to a default success message. Override this if you want
to report some other happy-friendly result


=cut

sub report_success {
    my $self = shift;
    $self->result->message("Updated")
}
1;
