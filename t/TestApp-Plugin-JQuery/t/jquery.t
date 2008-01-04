use strict;
use warnings;

use lib 't/lib';
use Jifty::SubTest;
use Jifty::Test tests => 9;
use Jifty::Test::WWW::Mechanize;

my $server = Jifty::Test->make_server;
ok($server, 'got a server');

my $url = $server->started_ok;

my $mech = Jifty::Test::WWW::Mechanize->new;

$mech->get_ok($url);
my ($script) = $mech->content =~ m{<script type="text/javascript" src="([^"]+)"></script>};
ok($script, "Found the script tag.");

$mech->get_ok($url . $script, "Fetched $url$script");
$mech->content_like(qr/^ \* jQuery (?:[\d\.]+) - New Wave Javascript/m,
    "Found the start of the jQuery script");
$mech->content_like(qr/^var jQuery = window\.jQuery = function\(/m, 
    "Found the main jQuery declaration");
$mech->content_like(qr/^ \* noConflict.js/m, 
    "Found the start of the noConflict script");
$mech->content_like(qr/^jQuery\.noConflict\(\);/m, 
    "Found the call to noConflict()");
