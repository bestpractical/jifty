#!/usr/bin/env perl

# CGI.pm 3.17 (and maybe earlier) would puke if you had regex metacharacters
# in the PATH_INFO.

use warnings;
use strict;

use Jifty::Test::Dist tests => 2;
use Jifty::Test::WWW::Mechanize;

my $server  = Jifty::Test->make_server;
my $URL     = $server->started_ok;
my $mech    = Jifty::Test::WWW::Mechanize->new();

$mech->get("$URL/*****");
is( $mech->status, '404', 'regex metachars in URL does not cause error' );
