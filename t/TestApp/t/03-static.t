#!/usr/bin/env perl
use warnings;
use strict;

use Jifty::Test::Dist tests => 6;
use Jifty::Test::WWW::Mechanize;

my $server  = Jifty::Test->make_server;

isa_ok($server, 'Jifty::TestServer');

my $URL     = $server->started_ok;
my $mech    = Jifty::Test::WWW::Mechanize->new();

for my $image (qw(pony.jpg)) {
    $mech->get_ok("$URL/images/$image");
    my $res = $mech->response;
    
    is($res->header('Content-Type'), 'image/jpeg', 'Content-Type is image/jpeg');
    like($res->status_line, qr/^200/, 'Serving out the request');
    is(length $res->content, 39186, 'Content is right length');
}

