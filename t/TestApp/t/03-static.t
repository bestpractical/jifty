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

use Jifty::Test tests => 6;
use Jifty::Test::WWW::Mechanize;

my $server  = Jifty::Test->make_server;

isa_ok($server, 'Jifty::Server');

my $URL     = $server->started_ok;
my $mech    = Jifty::Test::WWW::Mechanize->new();

for my $image (qw(pony.jpg)) {
    $mech->get_ok("$URL/images/$image");
    my $res = $mech->response;
    
    is($res->header('Content-Type'), 'image/jpeg', 'Content-Type is image/jpeg');
    like($res->status_line, qr/^200/, 'Serving out the request');
    is(length $res->content, 39186, 'Content is right length');
}

