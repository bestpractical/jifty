#!/usr/bin/env perl
use warnings;
use strict;

use Test::More;
BEGIN {
    if (eval { require Net::OAuth::Request; 1 } && eval { Net::OAuth::Request->VERSION('0.05') }) {
        plan tests => 58;
    }
    else {
        plan skip_all => "Net::OAuth 0.05 isn't installed";
    }
}

use lib 't/lib';
use Jifty::SubTest;

use TestApp::Plugin::OAuth::Test;

use Jifty::Test::WWW::Mechanize;

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

$umech->get_ok($URL . '/login');
$umech->fill_in_action_ok($umech->moniker_for('TestApp::Plugin::OAuth::Action::Login'), email => 'youzer@example.com', password => 'secret');
$umech->submit;
$umech->content_contains('Logout');
# }}}
# }}}
# make sure we're not logged in {{{
response_is(
    url                    => '/nuke/the/whales',
    code                   => 200,
    testname               => "200 - protected resource request",
    consumer_secret        => 'bar',
    oauth_consumer_key     => 'foo',
    oauth_signature_method => 'PLAINTEXT',
    oauth_token            => 'please',
    token_secret           => 'letmein',
);
$cmech->content_contains("Login with a password", "redirected to login");
$cmech->content_lacks("Press the shiny red button", "did NOT get to a protected page");
# }}}}
# basic protected request {{{
get_access_token();

response_is(
    url                    => '/nuke/the/whales',
    code                   => 200,
    testname               => "200 - protected resource request",
    consumer_secret        => 'bar',
    oauth_consumer_key     => 'foo',
    oauth_signature_method => 'PLAINTEXT',
    oauth_token            => $token_obj->token,
    token_secret           => $token_obj->secret,
);
$cmech->content_contains("Press the shiny red button", "got to a protected page");
$cmech->content_contains("human #1.", "correct current_user");
# }}}
# without OAuth parameters, no access {{{
$cmech->get_ok('/nuke/the/whales');

$cmech->content_contains("Login with a password", "current_user unset");
$cmech->content_lacks("Press the shiny red button", "did NOT get to a protected page");
$cmech->content_lacks("human #1.", "did NOT get to a protected page");
# }}}
# access tokens last for more than one hit {{{
response_is(
    url                    => '/nuke/the/whales',
    code                   => 200,
    testname               => "200 - protected resource request",
    consumer_secret        => 'bar',
    oauth_consumer_key     => 'foo',
    oauth_signature_method => 'PLAINTEXT',
    oauth_token            => $token_obj->token,
    token_secret           => $token_obj->secret,
);
$cmech->content_contains("Press the shiny red button", "got to a protected page");
$cmech->content_contains("human #1.", "correct current_user");
# }}}
# expired access token {{{
$token_obj->set_valid_until(DateTime->now->subtract(days => 1));

response_is(
    url                    => '/nuke/the/whales',
    code                   => 200,
    testname               => "200 - protected resource request",
    consumer_secret        => 'bar',
    oauth_consumer_key     => 'foo',
    oauth_signature_method => 'PLAINTEXT',
    oauth_token            => $token_obj->token,
    token_secret           => $token_obj->secret,
);
$cmech->content_contains("Login with a password", "redirected to login");
$cmech->content_lacks("Press the shiny red button", "did NOT get to a protected page");
$cmech->content_lacks("human #1.", "did NOT get to a protected page");
# }}}
# basic protected request {{{
get_access_token();
my $good_token = $token_obj;

response_is(
    url                    => '/nuke/the/whales',
    code                   => 200,
    testname               => "200 - protected resource request",
    consumer_secret        => 'bar',
    oauth_consumer_key     => 'foo',
    oauth_signature_method => 'PLAINTEXT',
    oauth_token            => $good_token->token,
    token_secret           => $good_token->secret,
);
$cmech->content_contains("Press the shiny red button", "got to a protected page");
$cmech->content_contains("human #1.", "correct current_user");
# }}}
# authorizing an access token through a protected resource request {{{
my $request_token = get_request_token();
$umech->get_ok('/oauth/authorize');
$umech->content_like(qr/If you trust this application/);

response_is(
    url                    => '/oauth/authorize',
    code                   => 403,
    testname               => "403 - not able to get to /oauth/authorize",
    no_token               => 1,
    consumer_secret        => 'bar',
    oauth_consumer_key     => 'foo',
    oauth_signature_method => 'PLAINTEXT',
    oauth_token            => $good_token->token,
    token_secret           => $good_token->secret,
);
# }}}
# the original user can still authorize tokens {{{
$token_obj = $request_token;
allow_ok();
get_access_token(1);
# }}}
# consumer can use either token {{{
response_is(
    url                    => '/nuke/the/whales',
    code                   => 200,
    testname               => "200 - protected resource request",
    consumer_secret        => 'bar',
    oauth_consumer_key     => 'foo',
    oauth_signature_method => 'PLAINTEXT',
    oauth_token            => $token_obj->token,
    token_secret           => $token_obj->secret,
);
$cmech->content_contains("Press the shiny red button", "got to a protected page");
$cmech->content_contains("human #1.", "correct current_user");

$token_obj = $good_token;
response_is(
    url                    => '/nuke/the/whales',
    code                   => 200,
    testname               => "200 - protected resource request",
    consumer_secret        => 'bar',
    oauth_consumer_key     => 'foo',
    oauth_signature_method => 'PLAINTEXT',
    oauth_token            => $good_token->token,
    token_secret           => $good_token->secret,
);
$cmech->content_contains("Press the shiny red button", "got to a protected page");
$cmech->content_contains("human #1.", "correct current_user");

# }}}
