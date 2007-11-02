#!/usr/bin/env perl
use warnings;
use strict;

use Test::More;
BEGIN {
    if (eval { require Net::OAuth::Request; require Crypt::OpenSSL::RSA; 1 }) {
        plan tests => 9;
    }
    else {
        plan skip_all => "Net::OAuth isn't installed";
    }
}

use lib 't/lib';
use Jifty::SubTest;
use TestApp::Plugin::OAuth::Test;

# sign PLAINTEXT {{{
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
# sign HMAC-SHA1 {{{
my ($sig, $sbs, $nrp) = sign(
    'GET',
    'pfkkdhi9sl3r4s00',
    'kd94hf93k423kf44',
    sign_url => 'http://photos.example.net/photos',
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
# sign RSA-SHA1 {{{
($sig, $sbs, $nrp) = sign(
    'GET',
    'pfkkdhi9sl3r4s00',
    'kd94hf93k423kf44',
    sign_url => 'http://photos.example.net/photos',
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
is($sig, 'oSjbUzMjD4E+LeHMaYzYx1KyULDwuR6V9oeNgTLoO9m90iJh4d01J/8SzvHKT8N0y2vs1o8s72z19Eicj6l+mEmH5Rp0cwWOE9UdvC+JdFSIA1bmlwVPCFL7jDQqRSBJsXEiT44T5j9P+Dh5Z5WUjEgCExQyNP38Z3nMnYYOCRM=', 'RSA-SHA1 signature correct');
# }}}

