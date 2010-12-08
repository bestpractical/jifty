package Jifty::TestServer::Inline;
use Any::Moose;
extends 'Jifty::TestServer';
use Test::More;

=head1 NAME

Jifty::TestServer::Inline - an inline server for running tests

=head1 METHODS

=head2 started_ok

Returns the URI for the test server.

=cut

sub started_ok {
    my $self = shift;
    my $port = $self->port;
    ok(1, "psgi test server ok");
    return "http://localhost:$port";
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;
