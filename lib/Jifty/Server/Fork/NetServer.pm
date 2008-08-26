package Jifty::Server::Fork::NetServer;

use base 'Net::Server::Fork';

=head1 NAME

Jifty::Server::Fork::NetServer - Sets up children for Jifty::Server::Fork

=head1 METHODS

=head2 post_accept_hook

After forking every connection, resetup the database connections so we
don't share them with our parent.

=cut

sub post_accept_hook {
    Jifty->setup_database_connection();
}

1;
