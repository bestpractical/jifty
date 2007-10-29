#!/usr/bin/env perl
use warnings;
use strict;

use lib 't/lib';
use Jifty::SubTest;

use TestApp::Plugin::OAuth::Test;

if (eval { require Net::OAuth::Request; require Crypt::OpenSSL::RSA; 1 }) {
    plan tests => 9;
}
else {
    plan skip_all => "Net::OAuth isn't installed";
}

use Jifty::Test::WWW::Mechanize;

my $server  = Jifty::Test->make_server;
isa_ok($server, 'Jifty::Server');
my $URL     = $server->started_ok;
$mech    = Jifty::Test::WWW::Mechanize->new();
$url     = $URL . '/oauth/request_token';

# create some consumers {{{
my $consumer = Jifty::Plugin::OAuth::Model::Consumer->new(current_user => Jifty::CurrentUser->superuser);
my ($ok, $msg) = $consumer->create(
    consumer_key => 'foo',
    secret       => 'bar',
    name         => 'FooBar industries',
    url          => 'http://foo.bar.example.com',
    rsa_key      => $pubkey,
);
ok($ok, $msg);

my $rsaless = Jifty::Plugin::OAuth::Model::Consumer->new(current_user => Jifty::CurrentUser->superuser);
($ok, $msg) = $rsaless->create(
    consumer_key => 'foo2',
    secret       => 'bar2',
    name         => 'Backwater.org',
    url          => 'http://backwater.org',
);
ok($ok, $msg);
# }}}
# get a request token as a known consumer (PLAINTEXT) {{{
response_is(
    code                   => 200,
    testname               => "200 - plaintext signature",
    consumer_secret        => 'bar',
    oauth_consumer_key     => 'foo',
    oauth_signature_method => 'PLAINTEXT',
);
# }}}

