use warnings;
use strict;

use Jifty::Test tests => 6;

use_ok('Jifty::Test::WWW::Mechanize');

my $server = Jifty::Test->make_server;
my $url = $server->started_ok;

my $mech = Jifty::Test::WWW::Mechanize->new;
ok($mech, 'contructed Jifty::Test::WWW::Mechanize');
isa_ok($mech, 'Jifty::Test::WWW::Mechanize');
isa_ok($mech, 'Test::WWW::Mechanize');
isa_ok($mech, 'WWW::Mechanize');

# XXX TODO need more tests to make sure that our mech can connect
# and do meaningful tests on a Jifty server
