use warnings;
use strict;

use Jifty::Test tests => 4;

use_ok ('Jifty::Client');

my $server=Jifty::Test->make_server;
isa_ok($server, 'Jifty::Server');

if ($server->isa('Jifty::TestServer::Plack')) {
    Jifty::Test->builder->todo_skip("This test is not using the test framework, and requires a server to connect to.  This doesn't work yet") for 1..2;
    exit 0;
}

my $URL = $server->started_ok;

my $client = Jifty::Client->new;

$client->get($URL);
ok($client->success(), "Jifty client can connect to the server");

# XXX TODO need more tests to make sure that our client can connect
# and do meaningful operations with a Jifty server
