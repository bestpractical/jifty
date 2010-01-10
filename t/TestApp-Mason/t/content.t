use strict;
use warnings;

use Test::More tests => 5;
use Jifty::Test::Dist;
use Jifty::Test::WWW::Mechanize;

my $server = Jifty::Test->make_server;
isa_ok($server, 'Jifty::TestServer');
my $URL  = $server->started_ok;
my $mech = Jifty::Test::WWW::Mechanize->new;
$mech->get_ok($URL . '/outer');

$mech->content_like( qr{start\s+howdy\s+end} );
$mech->content_unlike( qr{howdy\s+start\s+end} );
