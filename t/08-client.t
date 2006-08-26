use warnings;
use strict;

BEGIN {
    #### XXX: I know this is foolish but right now Jifty on Win32 fails to 
    #### unlink used test databases and the following tests fail saying
    #### 'error creating a table... table already exists'. So, remove the
    #### remnant first. And we should do it before none of the Jifty is there.

    my $testdb = 'jiftyapptest';
    if (-e $testdb) {
        unlink $testdb or die $!;
    }
}

use Jifty::Test tests => 4;

use_ok ('Jifty::Client');

my $server=Jifty::Test->make_server;
isa_ok($server, 'Jifty::Server');

my $URL = $server->started_ok;

my $client = Jifty::Client->new;

$client->get($URL);
ok($client->success(), "Jifty client can connect to the server");

# XXX TODO need more tests to make sure that our client can connect
# and do meaningful operations with a Jifty server