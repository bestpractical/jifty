#!/usr/bin/perl
use warnings;
use strict;

use Jifty::Test tests => 5;
use Jifty::Test::WWW::Mechanize;

my $server  = Jifty::Test->make_server;

isa_ok($server, 'Jifty::Server');

my $URL     = $server->started_ok;
my $mech    = Jifty::Test::WWW::Mechanize->new();

for my $image (qw(pony.jpg)) {
    $mech->get_ok("$URL/images/$image");
    my $res = $mech->response;
    
    is($res->header('Content-Type'), 'image/jpeg', 'Content-Type is image/jpeg');
    like($res->status_line, qr/^200 H::S::Mason OK$/, 'Status line is from Mason');
}

