package Ping::Server;
use base 'Jifty::Server';
use IO::Socket::INET;

sub net_server { 'Net::Server::Fork' }

1;
