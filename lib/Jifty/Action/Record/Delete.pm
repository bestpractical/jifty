use warnings;
use strict;

package Jifty::Action::Record::Delete;

=head1 NAME

Jifty::Action::Record::Delete - Automagic delete action

=head1 DESCRIPTION

This class is used as the base class for L<Jifty::Action>s that are
merely deleting L<Jifty::Record> objects.  To use it, subclass it and
override the C<record_class> method to return the name of the
L<Jifty::Record> subclass that this action should delete.

=cut

use base qw/Jifty::Action::Record/;

=head1 METHODS

=head2 arguments

Overrides the L<Jifty::Action::Record/arguments> method to specify
that all of the primary keys B<must> have values when submitted; that
is, they are L<constructors|Jifty::Manual::Glossary/constructors>.  No other
arguments are required.

=cut

sub arguments {
    my $self = shift;
    my $arguments = {};

    for my $pk (@{ $self->record->_primary_keys }) {
        $arguments->{$pk}{'constructor'} = 1;
        # XXX TODO IS THERE A BETTER WAY TO NOT RENDER AN ITEM IN arguments
        $arguments->{$pk}{'render_as'} = 'Unrendered'; 
        # primary key fields should always be hidden fields
    }
    return $arguments;
}

=head2 take_action

Overrides the virtual C<take_action> method on L<Jifty::Action> to
delete the row from the database.

=cut

sub take_action {
    my $self = shift;

    my $event_info = $self->_setup_event_before_action();

    my ( $val, $msg ) = $self->record->delete;
    $self->result->error($msg) if not $val and $msg;

    $self->report_success if not $self->result->failure;
    $self->_setup_event_after_action($event_info);

    return 1;
}

=head2 report_success

Sets the L<Jifty::Result/message> to default success message,
"Deleted". Override this if you want to report some other more
user-friendly result.

=cut

sub report_success {
    my $self = shift;
    $self->result->message(_("Deleted"))
}

1;
