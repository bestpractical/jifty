use warnings;
use strict;

package Jifty::Plugin::SetupWizard::Dispatcher;

=head1 NAME

Jifty::Plugin::SetupWizard::Dispatcher - dispatcher of the SetupWizard plugin

=head1 DESCRIPTION

Adds dispatching rules required for the SetupWizard plugin.

=cut

use Jifty::Dispatcher -base;

=head1 RULES

=head2 before '*'

Allows running L<Jifty::Plugin::SetupWizard::Action::TestDatabaseConnectivity>
if C<SetupMode> is turned on.

=cut

before '*' => run {
    return if not Jifty->setup_mode;
    Jifty->api->allow('Jifty::Plugin::SetupWizard::Action::TestDatabaseConnectivity');
};

1;
