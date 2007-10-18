#!/usr/bin/env perl
use warnings;
use strict;

use lib 't/lib';
use Jifty::SubTest;

use Jifty::Test tests => 9;
use Jifty::Test::WWW::Mechanize;

my $server  = Jifty::Test->make_server;
isa_ok($server, 'Jifty::Server');
my $URL     = $server->started_ok;
my $mech    = Jifty::Test::WWW::Mechanize->new();

$mech->get_ok($URL . '/oauth');
$mech->content_like(qr{/oauth/request_token}, "oauth page mentions request_token URL");
$mech->content_like(qr{/oauth/authorize}, "oauth page mentions authorize URL");
$mech->content_like(qr{/oauth/access_token}, "oauth page mentions access_token URL");

$mech->content_like(qr{http://oauth\.net/}, "oauth page mentions OAuth homepage");

$mech->get_ok($URL . '/oauth/authorize');
$mech->content_like(qr{If you trust this application}, "oauth authorization page exists without fancy headers");

