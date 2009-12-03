package Jifty::TestServer::Plack;
use strict;
use warnings;
use base 'Test::HTTP::Server::Simple';
use Test::More;

sub started_ok {
    my $self = shift;
    my $port = $self->port;
    ok(1, "plack test server ok");
    return "http://localhost:$port";
}

1;
