package Clock::Server;
use base 'Jifty::Server';

sub net_server { 'Net::Server::Fork' }

1;
