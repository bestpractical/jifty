#!/usr/bin/env perl
use warnings;
use strict;

use lib 't/lib';
use Jifty::SubTest;

use TestApp::Plugin::OAuth::Test tests => 50;
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

# success modes

# get a request token as a known consumer (PLAINTEXT) {{{
response_is(
    code                   => 200,
    testname               => "200 - plaintext signature",
    consumer_secret        => 'bar',
    oauth_consumer_key     => 'foo',
    oauth_signature_method => 'PLAINTEXT',
);
# }}}
# get a request token as a known consumer (HMAC-SHA1) {{{
$timestamp = 100; # set timestamp to test different consumers' timestamps
response_is(
    code                   => 200,
    testname               => "200 - HMAC-SHA1 signature",
    consumer_secret        => 'bar',
    oauth_consumer_key     => 'foo',
    oauth_signature_method => 'HMAC-SHA1',
);
# }}}
# get a request token as a known consumer (RSA-SHA1) {{{
response_is(
    code                   => 200,
    testname               => "200 - RSA-SHA1 signature",
    consumer_secret        => 'bar',
    oauth_consumer_key     => 'foo',
    signature_key          => $seckey,
    oauth_signature_method => 'RSA-SHA1',
);
# }}}

# get a request token as an RSA-less consumer (PLAINTEXT) {{{

# consumer 1 has a timestamp of about 101 now. if this gives a timestamp error,
# then timestamps must be globally increasing, which is wrong. they must only
# be increasing per consumer
$timestamp = 50;

response_is(
    code                   => 200,
    testname               => "200 - plaintext signature",
    consumer_secret        => 'bar2',
    oauth_consumer_key     => 'foo2',
    oauth_signature_method => 'PLAINTEXT',
);
# }}}
# get a request token as an RSA-less consumer (HMAC-SHA1) {{{
response_is(
    code                   => 200,
    testname               => "200 - HMAC-SHA1 signature",
    consumer_secret        => 'bar2',
    oauth_consumer_key     => 'foo2',
    oauth_signature_method => 'HMAC-SHA1',
);
# }}}

# failure modes

# request a request token as an RSA-less consumer (RSA-SHA1) {{{
response_is(
    code                   => 400,
    testname               => "400 - RSA-SHA1 signature, without registering RSA key!",
    consumer_secret        => 'bar2',
    oauth_consumer_key     => 'foo2',
    signature_key          => $seckey,
    oauth_signature_method => 'RSA-SHA1',
);
# }}}
# unknown consumer {{{
# we're back to the first consumer, so we need a locally larger timestamp
$timestamp = 200;
response_is(
    code                   => 401,
    testname               => "401 - unknown consumer",
    consumer_secret        => 'zzz',
    oauth_consumer_key     => 'whoami',
);
# }}}
# wrong consumer secret {{{
response_is (
    code                   => 401,
    testname               => "401 - wrong consumer secret",
    consumer_secret        => 'not bar!',
    oauth_consumer_key     => 'foo',
);
# }}}
# wrong signature {{{
response_is(
    code                   => 401,
    testname               => "401 - wrong signature",
    consumer_secret        => 'bar',
    oauth_consumer_key     => 'foo',
    oauth_signature        => 'hello ^____^',
);
# }}}
# duplicate timestamp and nonce {{{
response_is(
    code                   => 401,
    testname               => "401 - duplicate timestamp and nonce",
    consumer_secret        => 'bar',
    oauth_consumer_key     => 'foo',
    oauth_timestamp        => 1,
    oauth_nonce            => 1,
    oauth_signature_method => 'PLAINTEXT',
);
# }}}
# unknown signature method {{{
response_is(
    code                   => 400,
    testname               => "400 - unknown signature method",
    consumer_secret        => 'bar',
    oauth_consumer_key     => 'foo',
    oauth_signature_method => 'Peaches. Peaches FOR YOU',
);
# }}}
# missing parameters {{{
# oauth_consumer_key {{{
response_is(
    code                   => 400,
    testname               => "400 - missing parameter oauth_consumer_key",
    consumer_secret        => 'bar',
    oauth_signature_method => 'PLAINTEXT',
);
# }}}
# oauth_nonce {{{
response_is(
    code                   => 400,
    testname               => "400 - missing parameter oauth_nonce",
    consumer_secret        => 'bar',
    oauth_consumer_key     => 'foo',
    oauth_nonce            => undef,
    oauth_signature_method => 'PLAINTEXT',
);
# }}}
# oauth_timestamp {{{
response_is(
    code                   => 400,
    testname               => "400 - missing parameter oauth_timestamp",
    consumer_secret        => 'bar',
    oauth_consumer_key     => 'foo',
    oauth_timestamp        => undef,
    oauth_signature_method => 'PLAINTEXT',
);
# }}}
# oauth_signature_method {{{
response_is(
    code                   => 400,
    testname               => "400 - missing parameter oauth_signature_method",
    consumer_secret        => 'bar',
    oauth_consumer_key     => 'foo',
    oauth_signature_method => undef,
    _signature_method       => 'PLAINTEXT', # so we get a real signature
);
# }}}
# }}}
# unsupported parameter {{{
response_is(
    code                   => 400,
    testname               => "400 - unsupported parameter oauth_candy",
    consumer_secret        => 'bar',
    oauth_consumer_key     => 'foo',
    oauth_signature_method => 'PLAINTEXT',
    oauth_candy            => 'yummy',
);
# }}}
# invalid timestamp (noninteger) {{{
response_is(
    code                   => 400,
    testname               => "400 - malformed timestamp (noninteger)",
    consumer_secret        => 'bar',
    oauth_consumer_key     => 'foo',
    oauth_signature_method => 'PLAINTEXT',
    oauth_timestamp        => 'half past nine',
);
# }}}
# invalid timestamp (smaller than previous request) {{{
$timestamp = 1000;
# first make a good request with a large timestamp {{{
response_is(
    code                   => 200,
    testname               => "200 - setting up a future test",
    consumer_secret        => 'bar',
    oauth_consumer_key     => 'foo',
);
# }}}
$timestamp = 500;
# then a new request with a smaller timestamp {{{
response_is(
    code                   => 401,
    testname               => "401 - timestamp smaller than a previous timestamp",
    consumer_secret        => 'bar',
    oauth_consumer_key     => 'foo',
    oauth_signature_method => 'PLAINTEXT',
);
# }}}
$timestamp = 2000;
# }}}
# GET not POST {{{
response_is(
    code                   => 404,
    testname               => "404 - GET not supported for request_token",
    consumer_secret        => 'bar',
    oauth_consumer_key     => 'foo',
    oauth_signature_method => 'PLAINTEXT',
    method                 => 'GET',
);
# }}}

