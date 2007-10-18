#!/usr/bin/env perl
use warnings;
use strict;

use lib 't/lib';
use Jifty::SubTest;

use Jifty::Test tests => 9;
use Jifty::Test::WWW::Mechanize;

my $server  = Jifty::Test->make_server;
isa_ok($server, 'Jifty::Server');
my $URL     = $server->started_ok;
my $mech    = Jifty::Test::WWW::Mechanize->new();
my $url     = $URL . '/oauth/request_token';

# helper functions {{{
sub response_is ($%;$) {
    my ($code, $params, $testname) = @_;

    my $method          = (delete $params->{method})          || 'POST';
    my $token_secret    = (delete $params->{token_secret})    || '';
    my $consumer_secret = delete $params->{consumer_secret}
        or die "consumer_secret not passed to response_is!";

    $params->{oauth_signature} ||= sign($params, $method, $token_secret, $consumer_secret);

    my $r;

    if ($method eq 'POST') {
        $r = $mech->post($url);
    }
    else {
        $r = $mech->get($url);
    }

    is($r->code, $code, $testname || "Request got $code");
}

sub sign {
    my ($params, $method, $token_secret, $consumer_secret) = @_;

    my $normalized_request_parameters
        = join '&',
          map { "$_=" . Jifty->web->escape_uri($params->{$_}||'') }
          sort keys %$params;

    my $signature_base_string
        = join '&',
          map { Jifty->web->escape_uri($params->{$_}||'') }
              uc($method),
              $url,
              $normalized_request_parameters,
              $consumer_secret,
              $token_secret;

    # XXX: do some signing based on $params->{signature_method}!
    return '!!';
}
# }}}

# get a request token as a known consumer {{{
my $consumer = Jifty::Plugin::OAuth::Model::Consumer->new(current_user => Jifty::CurrentUser->superuser);
my ($ok, $msg) = $consumer->create(
    consumer_key => 'foo',
    secret => 'bar',
    name => 'FooBar industries',
    url => 'http://foo.bar.example.com',
);
ok($ok, $msg);


# }}}

# unknown consumer {{{
response_is 401, {
    consumer_secret        => 'zzz',
    oauth_consumer_key     => 'whoami',
    oauth_signature_method => 'RSA-SHA1',
    oauth_timestamp        => 100,
    oauth_nonce            => 'haa haa',
    oauth_version          => '1.0',
};
# }}}
# wrong secret {{{
# }}}
# wrong signature {{{
# }}}
# duplicate timestamp and nonce {{{
# }}}
# unknown signature method {{{
# }}}
# missing parameters {{{
# }}}
# unsupported parameter {{{
# }}}
# invalid timestamp (noninteger) {{{

# }}}
# invalid timestamp (smaller than previous request) {{{
# }}}
# GET not POST {{{
# }}}

