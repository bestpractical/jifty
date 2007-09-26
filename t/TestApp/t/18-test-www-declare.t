#!/usr/bin/env perl
use warnings;
use strict;

use lib 't/lib';
use Jifty::SubTest;

use Jifty::Test::WWW::Declare tests => 2;

# this is a duplication of t/TestApp/t/17-template-region-internal-redirect.t
# if the user sees failures here, then he either saw failures in t/17 OR
# J:T:W:D is broken

session user => run {
    flow "region with internal redirects" => check {
        get "$URL/region-with-internal-redirect";
        content should match qr/redirected ok/;
        content should match qr/other region/;
        content should match qr/still going/;
        content shouldnt match qr/sorry/;
    };
};

