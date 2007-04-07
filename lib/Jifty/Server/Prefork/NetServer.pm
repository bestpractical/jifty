
package Jifty::Server::Prefork::NetServer;

use base 'Net::Server::PreFork';

sub child_init_hook {
	Jifty->setup_database_connection();
}

1;
