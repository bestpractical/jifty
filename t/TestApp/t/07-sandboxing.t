#!/usr/bin/env perl
use warnings;
use strict;

use Jifty::Test::Dist tests => 104, actual_server => 1;
use Jifty::Test::WWW::Mechanize;
use Net::HTTP;
use URI;

my $server  = Jifty::Test->make_server;

isa_ok($server, 'Jifty::TestServer');

my $uri = URI->new($server->started_ok);
my $plugin = Jifty->find_plugin("Jifty::Plugin::TestServerWarnings");

my @requests = (
    "../../../../../../../../../etc/passwd"             => 404,
    "/../../../../../../../../../etc/passwd"            => 404,
    "/__jifty/../../../../../../../../../../etc/passwd" => 404,
    "/static/../../../../../../../../../../etc/passwd"  => 403,
    "../templates/index.html"                           => 404,
    "../templates/_elements/nav"                        => 404,
    "/static/../templates/_elements/nav"                => 403,
    "/static/css/../../templates/index.html"            => 403,
    "/static/css/../../templates/_elements/nav"         => 403,
    "/static/css/base.css"                              => qr/body/,
    "/static/css/../css/base.css"                       => 403,
    "/static/css//../css/base.css"                      => 403,
    "/somedir/stuff"                                    => qr/dhandler arg is stuff/,
    "/somedir/stuff/../things"                          => qr/dhandler arg is things/,
    "__jifty/webservices/yaml"                          => 404,
    "/__jifty//../__jifty/webservices/yaml"             => qr/--- {}/,
    "/__jifty/webservices/../webservices/yaml"          => qr/--- {}/,
    "///__jifty/webservices/yaml"                       => qr/--- {}/,
    "/__jifty/../index.html"                            => qr/pony/,
);

while (my ($path, $expect) = splice(@requests,0,2)) {
    my ($status, $body) = bogus_request($path);
    my $expect_status = $expect =~ /\D/ ? 200 : $expect;
    is($status, $expect_status, "Got a $status" );

    unlike( $body, qr/root/, "Doesn't have a root user in it");
    unlike( $body, qr{\Q<&|/_elements/\E|Jifty->web}, "Doesn't have the source code" );

    like( $body, $expect, "Has content" ) if $expect_status == 200;
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
