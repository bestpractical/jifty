#!/usr/bin/env perl
use warnings;
use strict;

BEGIN {
    #### XXX: I know this is foolish but right now Jifty on Win32 fails to 
    #### unlink used test databases and the following tests fail saying
    #### 'error creating a table... table already exists'. So, remove the
    #### remnant first. And we should do it before none of the Jifty is there.

    my $testdb = 't/TestApp/testapptest';
    if (-e $testdb) {
        unlink $testdb or die $!;
    }
}

use lib 't/lib';
use Jifty::SubTest;
use Jifty::Test tests => 28;
use Jifty::Test::WWW::Mechanize;

my $server  = Jifty::Test->make_server;

isa_ok($server, 'Jifty::Server');

my $URL     = $server->started_ok;
my $mech    = Jifty::Test::WWW::Mechanize->new();

$mech->get_ok("$URL/dispatch/basic", "Got /dispatch/basic");
$mech->content_contains("Basic test.");
$mech->content_contains("count: 0");
$mech->content_contains("before: 0");
$mech->content_contains("after: 0");
$mech->content_contains("after_once: 0");

$mech->get_ok("$URL/dispatch/basic-show", "Got /dispatch/basic-show");
$mech->content_contains("Basic test with forced show.");
$mech->content_contains("count: 1");
$mech->content_contains("before: 1");
$mech->content_contains("after: 1");
$mech->content_contains("after_once: 1");

$mech->get_ok("$URL/dispatch/show/", "Got /dispatch/show");
$mech->content_contains("Basic test with forced show.");
$mech->content_contains("count: 2");
$mech->content_lacks("count: 3");
$mech->content_contains("before: 3");
$mech->content_contains("after: 2");
$mech->content_contains("after_once: 2");

$mech->get_ok("$URL/dispatch/", "Got /dispatch/");
$mech->content_contains("Basic test.");
$mech->content_contains("count: 3");
$mech->content_lacks("count: 4");
$mech->content_contains("before: 4");
$mech->content_contains("after: 4");
$mech->content_contains("after_once: 3");



