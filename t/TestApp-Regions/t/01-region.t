#!/usr/bin/env perl
use strict;
use warnings;
use Jifty::Test::Dist tests => 1;
use Jifty::Test::WWW::Mechanize;

my $server = Jifty::Test->make_server;
isa_ok($server, 'Jifty::Server');

my $URL  = $server->started_ok;
my $mech = Jifty::Test::WWW::Mechanize->new;

$mech->get_ok($URL);

$mech->content_like(qr{
    <div \s+ class="mason-wrapper"> .*
        <div \s+ class="mason2-wrapper"> .*
            <h2>mason!</h2> .*
        </div> .*
    </div>
}x);
