package Jifty::Plugin::SetupWizard::Action::TestDatabaseConnectivity;
use strict;
use warnings;
use base 'Jifty::Action';

use Jifty::Param::Schema;
use Jifty::Action schema {
    param driver =>
        is mandatory,
        type is 'text',
        default is defer { Jifty->config->framework('Database')->{Driver} };

    param database =>
        is mandatory,
        type is 'text',
        default is defer { Jifty->config->framework('Database')->{Database} };

    param host =>
        type is 'text',
        default is defer { Jifty->config->framework('Database')->{Host} };

    param port =>
        type is 'integer',
        default is defer { Jifty->config->framework('Database')->{Port} };

    param user =>
        type is 'text',
        default is defer { Jifty->config->framework('Database')->{User} };

    param password =>
        type is 'password',
        default is defer { Jifty->config->framework('Database')->{Password} };

    param requiressl =>
        type is 'boolean',
        default is defer { Jifty->config->framework('Database')->{RequireSSL} };
};

sub take_action {
    my $self = shift;

    my $ok = Jifty::DBI::Handle->connect(
        %{ $self->argument_values },
    );

    return $ok;
}

1;

__END__

=head1 NAME

Jifty::Plugin::SetupWizard::Action::TestDatabaseConnectivity

=head1 METHODS

=head2 take_action

Tests the database connectivity!

=cut

