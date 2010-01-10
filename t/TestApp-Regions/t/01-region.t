#!/usr/bin/env perl
use strict;
use warnings;
use Jifty::Test::Dist tests => 5;
use Jifty::Test::WWW::Mechanize;

my $server = Jifty::Test->make_server;
isa_ok($server, 'Jifty::TestServer');

my $URL  = $server->started_ok;
my $mech = Jifty::Test::WWW::Mechanize->new;

$mech->get_ok($URL);

$mech->content_like(qr{
    <div \s+ id="mason-wrapper"> .*
        <div \s+ id="mason2-wrapper"> .*
            <h1>mason \s+ 2!</h1> .*
        </div> .*
    </div>
}xs);

$mech->content_unlike(qr{mason 2!.*mason2-wrapper}s);

