#!/usr/bin/env perl
use warnings;
use strict;

use Test::More;
BEGIN {
    if (eval { require Net::OAuth::Request; require Crypt::OpenSSL::RSA; 1 }) {
        plan tests => 71;
    }
    else {
        plan skip_all => "Net::OAuth isn't installed";
    }
}

use lib 't/lib';
use Jifty::SubTest;

use TestApp::Plugin::OAuth::Test;

use Jifty::Test::WWW::Mechanize;

my $server  = Jifty::Test->make_server;
isa_ok($server, 'Jifty::Server');
my $URL     = $server->started_ok;
$mech    = Jifty::Test::WWW::Mechanize->new();
$url     = $URL . '/oauth/access_token';

# helper functions {{{
sub get_request_token {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    response_is(
        url                    => $URL . '/oauth/request_token',
        code                   => 200,
        testname               => "200 - plaintext signature",
        consumer_secret        => 'bar',
        oauth_consumer_key     => 'foo',
        oauth_signature_method => 'PLAINTEXT',
        @_,
    );
    return $token_obj;
}

sub get_authorized_token {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    get_request_token(@_);
    allow_ok();
    return $token_obj;
}
# }}}
# setup {{{
# create two consumers {{{
my $consumer = Jifty::Plugin::OAuth::Model::Consumer->new(current_user => Jifty::CurrentUser->superuser);
my ($ok, $msg) = $consumer->create(
    consumer_key => 'foo',
    secret       => 'bar',
    name         => 'FooBar Industries',
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
# create user and log in {{{
my $u = TestApp::Plugin::OAuth::Model::User->new(current_user => TestApp::Plugin::OAuth::CurrentUser->superuser);
$u->create( name => 'You Zer', email => 'youzer@example.com', password => 'secret', email_confirmed => 1);
ok($u->id, "New user has valid id set");

$mech->get_ok($URL . '/login');
$mech->fill_in_action_ok($mech->moniker_for('TestApp::Plugin::OAuth::Action::Login'), email => 'youzer@example.com', password => 'secret');
$mech->submit;
$mech->content_contains('Logout');
# }}}
# }}}
# basic working access token {{{
get_authorized_token();
my $request_token = $token_obj->token;
response_is(
    code                   => 200,
    testname               => "200 - plaintext signature",
    consumer_secret        => 'bar',
    oauth_consumer_key     => 'foo',
    oauth_signature_method => 'PLAINTEXT',
);
isnt($token_obj->token, $request_token, "different token for request and access");
# }}}
# try to get an access token from denied request token {{{
get_request_token();
deny_ok();
response_is(
    code                   => 401,
    testname               => "401 - denied token",
    consumer_secret        => 'bar',
    oauth_consumer_key     => 'foo',
    oauth_signature_method => 'PLAINTEXT',
);
# }}}
# try to get an access token as a different consumer {{{
get_authorized_token();
$request_token = $token_obj;
response_is(
    code                   => 401,
    testname               => "401 - denied token",
    consumer_secret        => 'bar2',
    oauth_consumer_key     => 'foo2',
    oauth_signature_method => 'PLAINTEXT',
);
# }}}
# get that same access token as the original consumer {{{
$token_obj = $request_token;
response_is(
    code                   => 200,
    testname               => "200 - got token",
    consumer_secret        => 'bar',
    oauth_consumer_key     => 'foo',
    oauth_signature_method => 'PLAINTEXT',
);
# }}}
# same timestamp, different nonce {{{
get_authorized_token();
--$timestamp;
response_is(
    code                   => 200,
    testname               => "200 - plaintext signature",
    consumer_secret        => 'bar',
    oauth_consumer_key     => 'foo',
    oauth_signature_method => 'PLAINTEXT',
    oauth_nonce            => 'kjfh',
);
# }}}
# different timestamp, same nonce {{{
get_authorized_token();
response_is(
    code                   => 200,
    testname               => "200 - plaintext signature",
    consumer_secret        => 'bar',
    oauth_consumer_key     => 'foo',
    oauth_signature_method => 'PLAINTEXT',
    oauth_nonce            => 'kjfh',
);
# }}}
# duplicate timestamp and nonce as previous access token {{{
get_authorized_token();
$timestamp -= 2;
response_is(
    code                   => 401,
    testname               => "401 - duplicate ts/nonce as previous access",
    consumer_secret        => 'bar',
    oauth_consumer_key     => 'foo',
    oauth_signature_method => 'PLAINTEXT',
);
$timestamp += 100;
# }}}
# duplicate timestamp and nonce as request token {{{
get_authorized_token();
--$timestamp;
response_is(
    code                   => 401,
    testname               => "401 - duplicate ts/nonce for request token",
    consumer_secret        => 'bar',
    oauth_consumer_key     => 'foo',
    oauth_signature_method => 'PLAINTEXT',
);
# }}}
# same request token {{{
$token_obj = $request_token;
response_is(
    code                   => 401,
    testname               => "401 - already used",
    consumer_secret        => 'bar',
    oauth_consumer_key     => 'foo',
    oauth_signature_method => 'PLAINTEXT',
);
# }}}
# expired request token {{{
get_authorized_token();
$token_obj->set_valid_until(DateTime->now(time_zone => "GMT")->subtract(days => 1));
response_is(
    code                   => 401,
    testname               => "401 - expired",
    consumer_secret        => 'bar',
    oauth_consumer_key     => 'foo',
    oauth_signature_method => 'PLAINTEXT',
);
# }}}
# wrong consumer secret {{{
get_authorized_token();
response_is(
    code                   => 401,
    testname               => "401 - wrong secret",
    consumer_secret        => 'bah!',
    oauth_consumer_key     => 'foo',
    oauth_signature_method => 'PLAINTEXT',
);
# }}}

