use warnings;
use strict;
use Compress::Zlib;

=head1 DESCRIPTION

If we do a redirect in a 'before' in the dispatcher, actions should
still get run.

=cut

BEGIN { $ENV{'JIFTY_CONFIG'} = 't/config-Cachable' }
use Jifty::Test::Dist tests => 5;
use Jifty::Test::WWW::Mechanize;

my $server  = Jifty::Test->make_server;
my $URL     = $server->started_ok;

my $mech    = Jifty::Test::WWW::Mechanize->new();
my $request = HTTP::Request->new( GET => "$URL/", ['Accept-Encoding' => 'identity'] );

my $response = $mech->request($request);

my $expected = $mech->response->content;
like($expected, qr/Jifty Test Application/);

# now gzip

$request = HTTP::Request->new( GET => "$URL/", ['Accept-Encoding' => 'gzip'] );
$response = $mech->request( $request );

is($response->header('Content-Encoding'), 'gzip');
like(Compress::Zlib::memGunzip($response->content), qr/Jifty Test Application/);


$request = HTTP::Request->new( GET => "$URL/static/images/pony.jpg", ['Accept-Encoding' => 'gzip'] );
$response = $mech->request( $request );

is($response->header('Content-Encoding'), undef, 'image are not compressed');

