use warnings;
use strict;
use Compress::Zlib;

=head1 DESCRIPTION

If we do a redirect in a 'before' in the dispatcher, actions should
still get run.

=cut

BEGIN {
    #### XXX: I know this is foolish but right now Jifty on Win32 fails to 
    #### unlink used test databases and the following tests fail saying
    #### 'error creating a table... table already exists'. So, remove the
    #### remnant first. And we should do it before none of the Jifty is there.

    my $testdb = 't/TestApp/testapptest';
    if (-e $testdb) {
        unlink $testdb or die $!;
    }
}

use lib 't/lib';
use Jifty::SubTest;
BEGIN { $ENV{'JIFTY_CONFIG'} = 't/config-Cachable' }

use Jifty::Test tests => 5;
use Jifty::Test::WWW::Mechanize;

my $server  = Jifty::Test->make_server;
my $URL     = $server->started_ok;

my $mech    = Jifty::Test::WWW::Mechanize->new();
$mech->get_ok($URL);
my $expected = $mech->response->content;
like($expected, qr/Jifty Test Application/);

SKIP: {
skip "blah", 2;
my $request = HTTP::Request->new( GET => "$URL/", ['Accept-Encoding' => 'gzip'] );
my $response = $mech->request( $request );
is($response->header('Content-Encoding'), 'gzip');
# blah, can't check if this is same as expected because there are continuation serials.
like(Compress::Zlib::memGunzip($response->content), qr/Jifty Test Application/);
}
