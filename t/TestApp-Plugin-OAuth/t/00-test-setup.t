#!/usr/bin/env perl
use warnings;
use strict;

use Test::More;
BEGIN {
    if (eval { require Net::OAuth::Request; 1 } && eval { Net::OAuth::Request->VERSION('0.05') }) {
        plan tests => 10;
    }
    else {
        plan skip_all => "Net::OAuth 0.05 isn't installed";
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
is($sbs, 'GET&http%3A%2F%2Fphotos.example.net%2Fphotos&file%3Dvacation.jpg%26oauth_consumer_key%3Ddpf43f3p2l4k3l03%26oauth_nonce%3Dkllo9940pd9333jh%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D1191242096%26oauth_token%3Dnnch734d00sl2jdk%26oauth_version%3D1.0%26size%3Doriginal', 'HMAC-SHA1 signature-base-string correct');
is($sig, 'tR3+Ty81lMeYAr/Fid0kMTYa/WM=', 'HMAC-SHA1 signature correct');
# }}}
# sign RSA-SHA1 {{{
SKIP: {
    rsa_skip(3);

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
    is($sbs, 'GET&http%3A%2F%2Fphotos.example.net%2Fphotos&file%3Dvacation.jpg%26oauth_consumer_key%3Ddpf43f3p2l4k3l03%26oauth_nonce%3Dkllo9940pd9333jh%26oauth_signature_method%3DRSA-SHA1%26oauth_timestamp%3D1191242096%26oauth_token%3Dnnch734d00sl2jdk%26oauth_version%3D1.0%26size%3Doriginal', 'RSA-SHA1 signature-base-string correct');
    is($sig, 'NA2rGBEAnHta9amI/lwEHmuJzkDF2CtfzPNc+jbQIvsFKi0AyRQFi1etC+yxmHLn6bHKSHmn/pR4GOhN+2AP5fi0Aw9mr9n/k7LybUCUwRK/OjJH7b8ESXhkluss+UXCZoLOeaO9Pxskdi1DzWMOhY8si9hfYsCGrHrVbdcqwcw=', 'RSA-SHA1 signature correct');
}
# }}}

