#!/usr/bin/env perl

use warnings;
use strict;

=head1 DESCRIPTION

Creating a custom request and saving it in a continuation should work.

=cut

use lib '../../lib';
use Jifty::Test::Dist tests => 6, actual_server => 1;
use Jifty::Test::WWW::Mechanize;

my $server  = Jifty::Test->make_server;
my $URL     = $server->started_ok;
my $mech    = Jifty::Test::WWW::Mechanize->new();

$mech->get_ok($URL, "Got original page");
my $session = $mech->session;
isa_ok($session, "Jifty::Web::Session", "Got the session out");

my $cont;
{
    Jifty::Test->web;
    local Jifty->web->{session} = $session;
    my $req = Jifty::Request->new( path => "/otherplace" );
    my $result = Jifty::Result->new;
    $result->message("Result!");
    my $resp = Jifty::Response->new;
    $resp->result( yay => $result );
    $cont = Jifty::Continuation->new(
        request => $req,
        response => $resp,
    );
}

$mech->get_ok("$URL?J:CALL=".$cont->id, "Got answer");
like($mech->uri, qr{/otherplace}, "Ended up at redirect");
$mech->content_like(qr{Result!}, "Got result");


1;

