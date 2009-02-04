#!/usr/bin/env perl
use warnings;
use strict;

use Jifty::Test::Dist tests => 98;
use Jifty::Test::WWW::Mechanize;
use Net::HTTP;
use URI;

my $server  = Jifty::Test->make_server;

isa_ok($server, 'Jifty::Server');

my $uri = URI->new($server->started_ok);
my $plugin = Jifty->find_plugin("Jifty::Plugin::TestServerWarnings");

my ($status, $body);
($status, $body) = bogus_request("../../../../../../../../../etc/passwd");
isnt($status, 200, "Didn't get a 200" );
unlike( $body, qr/root/, "Doesn't have a root user in it");
is(scalar $plugin->decoded_warnings($uri), 1);

($status, $body) = bogus_request("/../../../../../../../../../etc/passwd");
isnt($status, 200, "Didn't get a 200" );
unlike( $body, qr/root/, "Doesn't have a root user in it");
is(scalar $plugin->decoded_warnings($uri), 1);

($status, $body) = bogus_request("/__jifty/../../../../../../../../../../etc/passwd");
isnt($status, 200, "Didn't get a 200" );
unlike( $body, qr/root/, "Doesn't have a root user in it");
is(scalar $plugin->decoded_warnings($uri), 1);

($status, $body) = bogus_request("/static/../../../../../../../../../../etc/passwd");
isnt($status, 200, "Didn't get a 200" );
unlike( $body, qr/root/, "Doesn't have a root user in it");
is(scalar $plugin->decoded_warnings($uri), 1);

($status, $body) = bogus_request("../templates/index.html");
isnt( $status, 200, "Didn't get a 200" );
unlike( $body, qr{\Q<&|/_elements/\E}, "Doesn't have the source code" );
is(scalar $plugin->decoded_warnings($uri), 1);

($status, $body) = bogus_request("../templates/_elements/nav");
isnt( $status, 200, "Didn't get a 200" );
unlike( $body, qr/Jifty->web->navigation/, "Doesn't have the source" );
is(scalar $plugin->decoded_warnings($uri), 1);

($status, $body) = bogus_request("/static/../templates/_elements/nav");
isnt( $status, 200, "Didn't get a 200" );
unlike( $body, qr/Jifty->web->navigation/, "Doesn't have the source" );
is(scalar $plugin->decoded_warnings($uri), 1);

($status, $body) = bogus_request("/static/css/../../templates/index.html");
isnt( $status, 200, "Didn't get a 200" );
unlike( $body, qr/Jifty->web->navigation/, "Doesn't have the source" );
is(scalar $plugin->decoded_warnings($uri), 1);

($status, $body) = bogus_request("/static/css/../../templates/_elements/nav");
isnt( $status, 200, "Didn't get a 200" );
unlike( $body, qr/Jifty->web->navigation/, "Doesn't have the source" );
is(scalar $plugin->decoded_warnings($uri), 1);

($status, $body) = bogus_request("/static/css/base.css");
is( $status, 200, "Got a 200" );
like( $body, qr/body/, "Has content" );
is(scalar $plugin->decoded_warnings($uri), 0);

($status, $body) = bogus_request("/static/css/../css/base.css");
is( $status, 200, "Got a 200" );
like( $body, qr/body/, "Has content" );
is(scalar $plugin->decoded_warnings($uri), 0);

($status, $body) = bogus_request("/static/css//../css/base.css");
is( $status, 200, "Got a 200" );
like( $body, qr/body/, "Has content" );
is(scalar $plugin->decoded_warnings($uri), 0);

($status, $body) = bogus_request("/somedir/stuff");
is( $status, 200, "Got a 200" );
like( $body, qr/dhandler arg is stuff/, "Has the content" );
is(scalar $plugin->decoded_warnings($uri), 0);

($status, $body) = bogus_request("/somedir/stuff/../things");
is( $status, 200, "Got a 200" );
like( $body, qr/dhandler arg is things/, "Has the right content" );
is(scalar $plugin->decoded_warnings($uri), 0);

($status, $body) = bogus_request("__jifty/webservices/yaml");
is( $status, 200, "Got a 200" );
like( $body, qr/--- {}/, "Got correct YAML response" );
is(scalar $plugin->decoded_warnings($uri), 0);

($status, $body) = bogus_request("/__jifty//../__jifty/webservices/yaml");
is( $status, 200, "Got a 200" );
like( $body, qr/--- {}/, "Got correct YAML response" );
is(scalar $plugin->decoded_warnings($uri), 0);

($status, $body) = bogus_request("/__jifty/webservices/../webservices/yaml");
is( $status, 200, "Got a 200" );
like( $body, qr/--- {}/, "Got correct YAML response" );
is(scalar $plugin->decoded_warnings($uri), 0);

($status, $body) = bogus_request("///__jifty/webservices/yaml");
is( $status, 200, "Got a 200" );
like( $body, qr/--- {}/, "Got correct YAML response" );
is(scalar $plugin->decoded_warnings($uri), 0);

($status, $body) = bogus_request("/__jifty/../index.html");
is( $status, 200, "Got a 200" );
unlike( $body, qr{\Q<&|/_elements/\E}, "Doesn't have the source code" );
like( $body, qr/pony/, "Has the output" );
is(scalar $plugin->decoded_warnings($uri), 0);

sub bogus_request {
    my $url = shift;
    my($body, $buffer);

    my $s = Net::HTTP->new( PeerHost => $uri->host, PeerPort => $uri->port || 80 );
    ok($s, "Connected to host");
    ok($s->write_request( GET => $url ), "Sent request $url");
    my $status = $s->read_response_headers;
    $body .= $buffer while $s->read_entity_body($buffer, 1000);

    return ($status, $body);
}
