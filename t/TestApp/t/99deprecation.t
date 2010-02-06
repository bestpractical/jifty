use warnings;
use strict;

BEGIN { $ENV{'JIFTY_CONFIG'} = 't/config-Cachable' }
use Jifty::Test::Dist tests => 3;
use Jifty::Test::WWW::Mechanize;

my $server  = Jifty::Test->make_server;
my $URL     = $server->started_ok;

my $mech    = Jifty::Test::WWW::Mechanize->new();
my $request = HTTP::Request->new( GET => "$URL/naughty");
my $response = $mech->request($request);
is($response->content, 'this is bad');
$mech->warnings_like(qr/deprecated/);

