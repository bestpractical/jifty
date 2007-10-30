#!/usr/bin/env perl
use warnings;
use strict;

use lib 't/lib';
use Jifty::SubTest;

use TestApp::Plugin::OAuth::Test;

if (eval { require Net::OAuth::Request; require Crypt::OpenSSL::RSA; 1 }) {
    plan tests => 33;
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
# try to navigate to protected pages while not logged in {{{
$mech->get_ok('/oauth/authorize');
$mech->content_unlike(qr/If you trust this application/);

$mech->get_ok('/nuke/the/whales');
$mech->content_unlike(qr/Press the shiny red button/);
# }}}
# log in {{{
my $u = TestApp::Plugin::OAuth::Model::User->new(current_user => TestApp::Plugin::OAuth::CurrentUser->superuser);
$u->create( name => 'You Zer', email => 'youzer@example.com', password => 'secret', email_confirmed => 1);
ok($u->id, "New user has valid id set");

$mech->get_ok('/login');
$mech->fill_in_action_ok($mech->moniker_for('TestApp::Plugin::OAuth::Action::Login'), email => 'youzer@example.com', password => 'secret');
$mech->submit;
$mech->save_content('m2.html');
$mech->content_contains('Logout');
# }}}
# try to navigate to protected pages while logged in {{{
$mech->get_ok('/oauth/authorize');
$mech->content_like(qr/If you trust this application/);

$mech->get_ok('/nuke/the/whales');
$mech->content_like(qr/Press the shiny red button/);
# }}}
# deny an unknown access token {{{
my $error = _authorize_request_token('Deny', 'deadbeef');
if ($error) {
    ok(0, $error);
}
else {
    $mech->content_contains("I don't know of that request token.");
}
# }}}
# allow an unknown access token {{{
$error = _authorize_request_token('Allow', 'hamburger');
if ($error) {
    ok(0, $error);
}
else {
    $mech->content_contains("I don't know of that request token.");
}
# }}}
# deny the above request token {{{
deny_ok();
# }}}
# try to use the denied request token {{{
$error = _authorize_request_token('Deny');
if ($error) {
    ok(0, $error);
}
else {
    $mech->content_contains("I don't know of that request token.");
}
# }}}
# get another request token as a known consumer (PLAINTEXT) {{{
response_is(
    code                   => 200,
    testname               => "200 - plaintext signature",
    consumer_secret        => 'bar',
    oauth_consumer_key     => 'foo',
    oauth_signature_method => 'PLAINTEXT',
);
# }}}
# allow the above request token {{{
allow_ok();
# }}}
# try to allow again {{{
$error = _authorize_request_token('Allow');
if ($error) {
    ok(0, $error);
}
else {
    $mech->content_contains("I don't know of that request token.");
}
# }}}
# get another request token as a known consumer (PLAINTEXT) {{{
response_is(
    code                   => 200,
    testname               => "200 - plaintext signature",
    consumer_secret        => 'bar',
    oauth_consumer_key     => 'foo',
    oauth_signature_method => 'PLAINTEXT',
);
# }}}
# expire the token, try to allow it {{{
my $late = Jifty::DateTime->now(time_zone => 'GMT')->subtract(minutes => 10);
$token_obj->set_valid_until($late);

$error = _authorize_request_token('Allow');
if ($error) {
    ok(0, $error);
}
else {
    $mech->content_contains("This request token has expired.");
}
# }}}
# try again, it should be deleted {{{
$error = _authorize_request_token('Allow');
if ($error) {
    ok(0, $error);
}
else {
    $mech->content_contains("I don't know of that request token.");
}
# }}}

