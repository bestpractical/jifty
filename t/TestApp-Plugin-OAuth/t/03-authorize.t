#!/usr/bin/env perl
use warnings;
use strict;

use Test::More;
BEGIN {
    if (eval { require Net::OAuth::Request; require Crypt::OpenSSL::RSA; 1 }) {
        plan tests => 86;
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
$url     = $URL . '/oauth/request_token';

# helper functions {{{
sub get_request_token {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    response_is(
        code                   => 200,
        testname               => "200 - plaintext signature",
        consumer_secret        => 'bar',
        oauth_consumer_key     => 'foo',
        oauth_signature_method => 'PLAINTEXT',
        @_,
    );
    return $token_obj;
}
# }}}
# create some consumers {{{
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

# try to navigate to protected pages while not logged in {{{
$mech->get_ok($URL . '/oauth/authorize');
$mech->content_unlike(qr/If you trust this application/);

$mech->get_ok('/oauth/authorized');
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
$mech->content_contains('Logout');
# }}}
# try to navigate to protected pages while logged in {{{
$mech->get_ok('/oauth/authorize');
$mech->content_like(qr/If you trust this application/);

$mech->get_ok('/oauth/authorized');
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
# deny request token {{{
get_request_token();
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
# allow request token {{{
get_request_token();
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
# expire a token, try to allow it {{{
get_request_token();

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

# deny token with a request parameter {{{
get_request_token();
$mech->get_ok('/oauth/authorize?oauth_token=' . $token_obj->token);
$mech->content_like(qr/If you trust this application/);
$mech->content_unlike(qr/should have provided it/, "token hint doesn't show up if we already have it");

$mech->form_number(1);
$mech->click_button(value => 'Deny');

$mech->content_contains("Denying FooBar Industries the right to access your stuff");
$mech->content_contains("click here");
$mech->content_contains("http://foo.bar.example.com?oauth_token=" . $token_obj->token);
$mech->content_contains("To return to");
$mech->content_contains("FooBar Industries");
# }}}
# allow token with a request parameter {{{
get_request_token();
$mech->get_ok('/oauth/authorize?oauth_token=' . $token_obj->token);
$mech->content_like(qr/If you trust this application/);
$mech->content_unlike(qr/should have provided it/, "token hint doesn't show up if we already have it");

$mech->form_number(1);
$mech->click_button(value => 'Allow');

$mech->content_contains("Allowing FooBar Industries to access your stuff");
$mech->content_contains("click here");
$mech->content_contains("http://foo.bar.example.com?oauth_token=" . $token_obj->token);
$mech->content_contains("To return to");
$mech->content_contains("FooBar Industries");
# }}}
# deny token with a callback {{{
get_request_token();
$mech->get_ok('/oauth/authorize?oauth_callback=http%3A%2f%2fgoogle.com');
$mech->content_like(qr/If you trust this application/);

$mech->fill_in_action_ok($mech->moniker_for('TestApp::Plugin::OAuth::Action::AuthorizeRequestToken'), token => $token_obj->token);
$mech->click_button(value => 'Deny');

$mech->content_contains("Denying FooBar Industries the right to access your stuff");
$mech->content_contains("click here");
$mech->content_contains("http://google.com?oauth_token=" . $token_obj->token);
$mech->content_contains("To return to");
$mech->content_contains("FooBar Industries");
# }}}
# deny it with a callback + request params {{{
get_request_token();
$mech->get_ok('/oauth/authorize?oauth_token='.$token_obj->token.'&oauth_callback=http%3A%2F%2Fgoogle.com%2F%3Ffoo%3Dbar');
$mech->content_like(qr/If you trust this application/);
$mech->content_unlike(qr/should have provided it/, "token hint doesn't show up if we already have it");

$mech->form_number(1);
$mech->click_button(value => 'Deny');

$mech->content_contains("Denying FooBar Industries the right to access your stuff");
$mech->content_contains("click here");
my $token = $token_obj->token;
$mech->content_like(qr{http://google\.com/\?foo=bar&(?:amp;|#38;)?oauth_token=$token});
$mech->content_contains("To return to");
$mech->content_contains("FooBar Industries");
# }}}

# authorizing a token refreshes its valid_until {{{
get_request_token();
my $in_ten = DateTime->now(time_zone => "GMT")->add(minutes => 10);
$token_obj->set_valid_until($in_ten->clone);

my $id = $token_obj->id;
undef $token_obj;
$token_obj = Jifty::Plugin::OAuth::Model::RequestToken->new(current_user => Jifty::CurrentUser->superuser);
$token_obj->load($id);

allow_ok();

undef $token_obj;
$token_obj = Jifty::Plugin::OAuth::Model::RequestToken->new(current_user => Jifty::CurrentUser->superuser);
$token_obj->load($id);

my $difference = $token_obj->valid_until - $in_ten;

TODO: {
    local $TODO = "some kind of caching issue, serverside it works fine";
    ok($difference->minutes > 15, "valid for more than 15 minutes");
}
# }}}

