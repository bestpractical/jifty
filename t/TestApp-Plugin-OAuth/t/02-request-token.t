#!/usr/bin/env perl
use warnings;
use strict;

use lib 't/lib';
use Jifty::SubTest;

use Jifty::Test tests => 16;
use Jifty::Test::WWW::Mechanize;

use MIME::Base64;
use Crypt::OpenSSL::RSA;
use Digest::HMAC_SHA1 'hmac_sha1';

my $server  = Jifty::Test->make_server;
isa_ok($server, 'Jifty::Server');
my $URL     = $server->started_ok;
my $mech    = Jifty::Test::WWW::Mechanize->new();
our $url     = $URL . '/oauth/request_token';

# helper functions {{{
my $timestamp = 0;
sub response_is {
    ++$timestamp;

    my %params = (
        oauth_timestamp        => $timestamp,
        oauth_nonce            => scalar(reverse $timestamp),
        oauth_signature_method => 'HMAC-SHA1',
        oauth_version          => '1.0',

        code                   => 400,
        testname               => "",
        method                 => 'POST',
        token_secret           => '',
        @_,
    );

    my $code            = delete $params{code};
    my $testname        = delete $params{testname} || "Response was $code";
    my $method          = delete $params{method};
    my $token_secret    = delete $params{token_secret};
    my $consumer_secret = delete $params{consumer_secret}
        or die "consumer_secret not passed to response_is!";

    $params{oauth_signature} ||= sign($method, $token_secret, $consumer_secret, %params);

    my $r;

    if ($method eq 'POST') {
        $r = $mech->post($url, [%params]);
    }
    else {
        my $query = join '&',
                    map { "$_=" . Jifty->web->escape_uri($params{$_}||'') }
                    keys %params;
        $r = $mech->get("$url?$query");
    }

    is($r->code, $code, $testname);
}

sub sign {
    my ($method, $token_secret, $consumer_secret, %params) = @_;

    local $url = delete $params{url} || $url;

    my $key = delete $params{signature_key};

    if ($params{oauth_signature_method} eq 'PLAINTEXT') {
        my $signature = join '&',
                        map { Jifty->web->escape_uri($_||'') }
                            $consumer_secret,
                            $token_secret;
        return $signature;
    }

    my $normalized_request_parameters
        = join '&',
          map { "$_=" . Jifty->web->escape_uri($params{$_}||'') }
          sort keys %params;

    my $signature_base_string
        = join '&',
          map { Jifty->web->escape_uri($_||'') }
              uc($method),
              $url,
              $normalized_request_parameters,
              $consumer_secret,
              $token_secret;

    my $signature;

    if ($params{oauth_signature_method} eq 'RSA-SHA1') {
        my $pubkey = Crypt::OpenSSL::RSA->new_private_key($key);
        $signature = encode_base64($pubkey->sign($signature_base_string));
    }
    elsif ($params{oauth_signature_method} eq 'HMAC-SHA1') {
        my $key = join '&',
          map { Jifty->web->escape_uri($_||'') }
              $consumer_secret,
              $token_secret;
        my $hmac = Digest::HMAC_SHA1->new($key);
        $hmac->add($signature_base_string);
        $signature = $hmac->b64digest;
    }

    return ($signature, $signature_base_string, $normalized_request_parameters)
        if wantarray;
    return $signature;

}
# }}}
# load the RSA keys {{{
sub slurp {
    my $file = shift;
    local $/;
    local @ARGV = $file;
    my $contents = scalar <>
        or die "Unable to slurp $file";
    return $contents;
}

my $pubkey = slurp 't/id_rsa.pub';
my $seckey = slurp 't/id_rsa';
# }}}
# testing the local sign function {{{
# PLAINTEXT {{{
is(sign('POST', 'jjd999tj88uiths3', 'djr9rjt0jd78jf88',
        oauth_signature_method => 'PLAINTEXT'),
    'djr9rjt0jd78jf88&jjd999tj88uiths3', 'PLAINTEXT example 1 works');
is(sign('POST', 'jjd99$tj88uiths3', 'djr9rjt0jd78jf88',
        oauth_signature_method => 'PLAINTEXT'),
    'djr9rjt0jd78jf88&jjd99%24tj88uiths3', 'PLAINTEXT example 2 works');
is(sign('POST', undef, 'djr9rjt0jd78jf88',
        oauth_signature_method => 'PLAINTEXT'),
    'djr9rjt0jd78jf88&', 'PLAINTEXT example 2 works');
# }}}
# HMAC-SHA1 {{{
my ($sig, $sbs, $nrp) = sign(
    'GET',
    'pfkkdhi9sl3r4s00',
    'kd94hf93k423kf44',
    url => 'http://photos.example.net/photos',
    oauth_consumer_key => 'dpf43f3p2l4k3l03',
    oauth_signature_method => 'HMAC-SHA1',
    oauth_timestamp => '1191242096',
    oauth_nonce => 'kllo9940pd9333jh',
    oauth_token => 'nnch734d00sl2jdk',
    file => 'vacation.jpg',
    size => 'original',
    oauth_version => '1.0');

is($nrp, 'file=vacation.jpg&oauth_consumer_key=dpf43f3p2l4k3l03&oauth_nonce=kllo9940pd9333jh&oauth_signature_method=HMAC-SHA1&oauth_timestamp=1191242096&oauth_token=nnch734d00sl2jdk&oauth_version=1.0&size=original', 'HMAC-SHA1 normalized request paramaters correct');
is($sbs, 'GET&http%3A%2F%2Fphotos.example.net%2Fphotos&file%3Dvacation.jpg%26oauth_consumer_key%3Ddpf43f3p2l4k3l03%26oauth_nonce%3Dkllo9940pd9333jh%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D1191242096%26oauth_token%3Dnnch734d00sl2jdk%26oauth_version%3D1.0%26size%3Doriginal&kd94hf93k423kf44&pfkkdhi9sl3r4s00', 'HMAC-SHA1 signature-base-string correct');
is($sig, 'Gcg/323lvAsQ707p+y41y14qWfY', 'HMAC-SHA1 signature correct');
# }}}
# RSA-SHA1 {{{
($sig, $sbs, $nrp) = sign(
    'GET',
    'pfkkdhi9sl3r4s00',
    'kd94hf93k423kf44',
    url => 'http://photos.example.net/photos',
    signature_key => $seckey,
    oauth_consumer_key => 'dpf43f3p2l4k3l03',
    oauth_signature_method => 'RSA-SHA1',
    oauth_timestamp => '1191242096',
    oauth_nonce => 'kllo9940pd9333jh',
    oauth_token => 'nnch734d00sl2jdk',
    file => 'vacation.jpg',
    size => 'original',
    oauth_version => '1.0');

is($nrp, 'file=vacation.jpg&oauth_consumer_key=dpf43f3p2l4k3l03&oauth_nonce=kllo9940pd9333jh&oauth_signature_method=RSA-SHA1&oauth_timestamp=1191242096&oauth_token=nnch734d00sl2jdk&oauth_version=1.0&size=original', 'RSA-SHA1 normalized request paramaters correct');
is($sbs, 'GET&http%3A%2F%2Fphotos.example.net%2Fphotos&file%3Dvacation.jpg%26oauth_consumer_key%3Ddpf43f3p2l4k3l03%26oauth_nonce%3Dkllo9940pd9333jh%26oauth_signature_method%3DRSA-SHA1%26oauth_timestamp%3D1191242096%26oauth_token%3Dnnch734d00sl2jdk%26oauth_version%3D1.0%26size%3Doriginal&kd94hf93k423kf44&pfkkdhi9sl3r4s00', 'RSA-SHA1 signature-base-string correct');
$sig =~ s/\s+//g;
is($sig, 'oSjbUzMjD4E+LeHMaYzYx1KyULDwuR6V9oeNgTLoO9m90iJh4d01J/8SzvHKT8N0y2vs1o8s72z19Eicj6l+mEmH5Rp0cwWOE9UdvC+JdFSIA1bmlwVPCFL7jDQqRSBJsXEiT44T5j9P+Dh5Z5WUjEgCExQyNP38Z3nMnYYOCRM=', 'RSA-SHA1 signature correct');
# }}}
# }}}
# get a request token as a known consumer {{{
my $consumer = Jifty::Plugin::OAuth::Model::Consumer->new(current_user => Jifty::CurrentUser->superuser);
my ($ok, $msg) = $consumer->create(
    consumer_key => 'foo',
    secret       => 'bar',
    name         => 'FooBar industries',
    url          => 'http://foo.bar.example.com',
    rsa_key      => $pubkey,
);
ok($ok, $msg);

response_is(
    code                   => 200,
    consumer_secret        => 'bar',
    oauth_consumer_key     => 'foo',
    oauth_signature_method => 'PLAINTEXT',
);
# }}}
# unknown consumer {{{
response_is(
    code                   => 401,
    consumer_secret        => 'zzz',
    oauth_consumer_key     => 'whoami',
);
# }}}
# wrong secret {{{
response_is (
    code                   => 401,
    consumer_secret        => 'not bar!',
    oauth_consumer_key     => 'foo',
);
# }}}
# wrong signature {{{
response_is(
    code                   => 401,
    consumer_secret        => 'bar',
    oauth_consumer_key     => 'foo',
);
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

