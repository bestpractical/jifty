#!/usr/bin/env perl
use warnings;
use strict;

use Test::More;
BEGIN {
    if (eval { require Net::OAuth::Request; 1 } && eval { Net::OAuth::Request->VERSION('0.05') }) {
        plan tests => 85;
    }
    else {
        plan skip_all => "Net::OAuth 0.05 isn't installed";
    }
}

use lib 't/lib';
use Jifty::SubTest;

use TestApp::Plugin::OAuth::Test;

use Jifty::Test::WWW::Mechanize;
start_server();

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
$umech->get_ok($URL . '/oauth/authorize');
$umech->content_unlike(qr/If you trust this application/);

$umech->get_ok('/oauth/authorized');
$umech->content_unlike(qr/If you trust this application/);

$umech->get_ok('/nuke/the/whales');
$umech->content_unlike(qr/Press the shiny red button/);
# }}}
# log in {{{
my $u = TestApp::Plugin::OAuth::Model::User->new(current_user => TestApp::Plugin::OAuth::CurrentUser->superuser);
$u->create( name => 'You Zer', email => 'youzer@example.com', password => 'secret', email_confirmed => 1);
ok($u->id, "New user has valid id set");

$umech->get_ok('/login');
$umech->fill_in_action_ok($umech->moniker_for('TestApp::Plugin::OAuth::Action::Login'), email => 'youzer@example.com', password => 'secret');
$umech->submit;
$umech->content_contains('Logout');
# }}}
# try to navigate to protected pages while logged in {{{
$umech->get_ok('/oauth/authorize');
$umech->content_like(qr/If you trust this application/);

$umech->get_ok('/oauth/authorized');
$umech->content_like(qr/If you trust this application/);

$umech->get_ok('/nuke/the/whales');
$umech->content_like(qr/Press the shiny red button/);
# }}}
# deny an unknown access token {{{
my $error = _authorize_request_token('Deny', 'deadbeef');
if ($error) {
    ok(0, $error);
}
else {
    $umech->content_contains("I don't know of that request token.");
}
# }}}
# allow an unknown access token {{{
$error = _authorize_request_token('Allow', 'hamburger');
if ($error) {
    ok(0, $error);
}
else {
    $umech->content_contains("I don't know of that request token.");
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
    $umech->content_contains("I don't know of that request token.");
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
    $umech->content_contains("I don't know of that request token.");
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
    $umech->content_contains("This request token has expired.");
}
# }}}
# try again, it should be deleted {{{
$error = _authorize_request_token('Allow');
if ($error) {
    ok(0, $error);
}
else {
    $umech->content_contains("I don't know of that request token.");
}
# }}}

# deny token with a request parameter {{{
get_request_token();
$umech->get_ok('/oauth/authorize?oauth_token=' . $token_obj->token);
$umech->content_like(qr/If you trust this application/);
$umech->content_unlike(qr/should have provided it/, "token hint doesn't show up if we already have it");

$umech->form_number(1);
$umech->click_button(value => 'Deny');

$umech->content_contains("Denying FooBar Industries the right to access your data.");
$umech->content_contains("click here");
$umech->content_contains("http://foo.bar.example.com?oauth_token=" . $token_obj->token);
$umech->content_contains("To return to");
$umech->content_contains("FooBar Industries");
# }}}
# allow token with a request parameter {{{
get_request_token();
$umech->get_ok('/oauth/authorize?oauth_token=' . $token_obj->token);
$umech->content_like(qr/If you trust this application/);
$umech->content_unlike(qr/should have provided it/, "token hint doesn't show up if we already have it");

$umech->form_number(1);
$umech->click_button(value => 'Allow');

$umech->content_contains("Allowing FooBar Industries to read your data for 1 hour.");
$umech->content_contains("click here");
$umech->content_contains("http://foo.bar.example.com?oauth_token=" . $token_obj->token);
$umech->content_contains("To return to");
$umech->content_contains("FooBar Industries");
# }}}
# deny token with a callback {{{
get_request_token();
$umech->get_ok('/oauth/authorize?oauth_callback=http%3A%2f%2fgoogle.com');
$umech->content_like(qr/If you trust this application/);

$umech->fill_in_action_ok($umech->moniker_for('TestApp::Plugin::OAuth::Action::AuthorizeRequestToken'), token => $token_obj->token);
$umech->click_button(value => 'Deny');

$umech->content_contains("Denying FooBar Industries the right to access your data.");
$umech->content_contains("click here");
$umech->content_contains("http://google.com?oauth_token=" . $token_obj->token);
$umech->content_contains("To return to");
$umech->content_contains("FooBar Industries");
# }}}
# deny it with a callback + request params {{{
get_request_token();
$umech->get_ok('/oauth/authorize?oauth_token='.$token_obj->token.'&oauth_callback=http%3A%2F%2Fgoogle.com%2F%3Ffoo%3Dbar');
$umech->content_like(qr/If you trust this application/);
$umech->content_unlike(qr/should have provided it/, "token hint doesn't show up if we already have it");

$umech->form_number(1);
$umech->click_button(value => 'Deny');

$umech->content_contains("Denying FooBar Industries the right to access your data.");
$umech->content_contains("click here");
my $token = $token_obj->token;
$umech->content_like(qr{http://google\.com/\?foo=bar&(?:amp;|#38;)?oauth_token=$token});
$umech->content_contains("To return to");
$umech->content_contains("FooBar Industries");
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

