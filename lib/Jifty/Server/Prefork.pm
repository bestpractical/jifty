package Jifty::Server::Prefork;
use Net::Server::PreFork ();
use base 'Jifty::Server';

=head1 NAME

Jifty::Server::Prefork - Jifty::Server that supports multiple connections

=head1 SYNOPSIS

In your F<etc/config.yml>:

  framework:
    Web:
      ServerClass: Jifty::Server::Prefork

=head1 METHODS

=head2 net_server

This module depends on the L<Net::Server::Prefork> module, which is part of
the L<Net::Server> CPAN distribution.

=cut

sub net_server { 'Jifty::Server::Prefork::NetServer' }


1;
