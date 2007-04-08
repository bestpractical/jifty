package Jifty::Server::Prefork::NetServer;

use base 'Net::Server::PreFork';

=head1 NAME

Jifty::Server::Prefork::NetServer - Sets up children for Jifty::Server::Prefork

=head1 METHODS

=head2 child_init_hook

Sets up the database connection when spawning a new child

=cut

sub child_init_hook {
	Jifty->setup_database_connection();
}

1;
