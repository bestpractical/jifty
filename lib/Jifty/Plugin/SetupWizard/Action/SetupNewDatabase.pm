package Jifty::Plugin::SetupWizard::Action::SetupNewDatabase;
use strict;
use warnings;
use base 'Jifty::Action';

=head1 NAME

Jifty::Plugin::SetupWizard::Action::SetupNewDatabase - Fully create the
database specified by the current config

=head1 PARAMETERS

Takes no parameters.

=head1 METHODS

=head2 take_action

Creates the database specified in the current config and populates it with
tables and bootstrapped content.

This is roughly equivalent to running C<jifty schema --create-database --setup>,
although this happens while the app is running and as a result needs
a little more finesse.  Running the action will call Jifty's L<Jifty/restart>
method.

=cut

use Jifty::Param::Schema;
use Jifty::Action schema {
    # No parameters
};

use Jifty::Schema;

sub take_action {
    my $self = shift;

    my $database = Jifty->handle->canonical_database_name();

    eval {
        Jifty::Schema->new->setup_database();
        Jifty->restart();
    };

    my $error = $@;

    if ( $error ) {
        return $self->result->error(_("Setting up the new database '%1' failed. %2",
                                      $database, $error));
    }
    else {
        return $self->result->message(_("Setup the new database '%1'.", $database));
    }
}

1;
