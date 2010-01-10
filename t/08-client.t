use warnings;
use strict;

use Jifty::Test tests => 4, actual_server => 1;

use_ok ('Jifty::Client');

my $server=Jifty::Test->make_server;
isa_ok($server, 'Jifty::TestServer');

my $URL = $server->started_ok;

my $client = Jifty::Client->new;

$client->get($URL);
ok($client->success(), "Jifty client can connect to the server");

# XXX TODO need more tests to make sure that our client can connect
# and do meaningful operations with a Jifty server
