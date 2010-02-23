use strict;
use warnings;

use Test::More tests => 5;
use Jifty::Test::Dist;
use Jifty::Test::WWW::Mechanize;

my $server = Jifty::Test->make_server;
isa_ok($server, 'Jifty::TestServer');
my $URL  = $server->started_ok;
my $mech = Jifty::Test::WWW::Mechanize->new;
$mech->get_ok($URL . '/foo');

$mech->content_like(qr{this is foo/index.html});
$mech->content_unlike(qr{this is foo/dhandler});
