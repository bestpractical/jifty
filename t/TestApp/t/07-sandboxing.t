#!/usr/bin/env perl
use warnings;
use strict;

use Jifty::Test::Dist tests => 125;
use Jifty::Test::WWW::Mechanize;
use Net::HTTP;
use URI;

my $server  = Jifty::Test->make_server;

isa_ok($server, 'Jifty::Server');

if ($server->isa('Jifty::TestServer::Plack')) {
    Jifty::Test->builder->todo_skip("This test is not using the test framework, and requires a server to connect to.  This doesn't work yet") for 1..124;
    exit 0;
}

my $uri = URI->new($server->started_ok);
my $plugin = Jifty->find_plugin("Jifty::Plugin::TestServerWarnings");

my @bogus = qw{
    ../../../../../../../../../etc/passwd
    /../../../../../../../../../etc/passwd
    /__jifty/../../../../../../../../../../etc/passwd
    /static/../../../../../../../../../../etc/passwd
    ../templates/index.html
    ../templates/_elements/nav
    /static/../templates/_elements/nav
    /static/css/../../templates/index.html
    /static/css/../../templates/_elements/nav
};

for my $path (@bogus) {
    my ($status, $body) = bogus_request($path);
    isnt($status, 200, "Didn't get a 200" );
    unlike( $body, qr/root/, "Doesn't have a root user in it");
    unlike( $body, qr{\Q<&|/_elements/\E}, "Doesn't have the source code" );
    unlike( $body, qr/Jifty->web->navigation/, "Doesn't have the source" );
    is(scalar $plugin->decoded_warnings($uri), 1);
}

my %ok = (
    "/static/css/base.css" => qr/body/,
    "/static/css/../css/base.css" => qr/body/,
    "/static/css//../css/base.css" => qr/body/,
    "/somedir/stuff" => qr/dhandler arg is stuff/,
    "/somedir/stuff/../things" => qr/dhandler arg is things/,
    "__jifty/webservices/yaml" => qr/--- {}/,
    "/__jifty//../__jifty/webservices/yaml" => qr/--- {}/,
    "/__jifty/webservices/../webservices/yaml" => qr/--- {}/,
    "///__jifty/webservices/yaml" => qr/--- {}/,
    "/__jifty/../index.html" => qr/pony/,
);

for my $path (keys %ok) {
    my ($status, $body) = bogus_request($path);
    is( $status, 200, "Got a 200" );
    like( $body, $ok{$path}, "Has content" );
    unlike( $body, qr{\Q<&|/_elements/\E}, "Doesn't have the source code" );
    is(scalar $plugin->decoded_warnings($uri), 0);
}

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
