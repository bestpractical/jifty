package Jifty::Server::Fork;
use Net::Server::Fork ();
use base 'Jifty::Server';

=head1 NAME

Jifty::Server::Fork - Jifty::Server that supports multiple connections

=head1 SYNOPSIS

In your F<etc/config.yml>:

  framework:
    Web:
      ServerClass: Jifty::Server::Fork

=head1 METHODS

=head2 net_server

This module depends on the L<Net::Server::Fork> module, which is part of
the L<Net::Server> CPAN distribution.

=cut

sub net_server { 'Jifty::Server::Fork::NetServer' }

1;
