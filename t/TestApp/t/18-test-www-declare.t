#!/usr/bin/env perl
use warnings;
use strict;

use Jifty::Test::Dist qw//;
use Test::More;

BEGIN {
    unless (eval { require Test::WWW::Declare }) {
        plan skip_all => "Test::WWW::Declare isn't installed";
    }
    plan skip_all => "This test is not using the test framework, and requires a server to connect to.  This doesn't work yet";

}

use Jifty::Test::WWW::Declare tests => 2;

# this is a duplication of t/TestApp/t/17-template-region-internal-redirect.t
# if the user sees failures here, then he either saw failures in t/17 OR
# J:T:W:D is broken

session user => run {
    flow "region with internal redirects" => check {
        get "region-with-internal-redirect";
        content should match qr/redirected ok/;
        content should match qr/other region/;
        content should match qr/still going/;
        content shouldnt match qr/sorry/;
    };
};

