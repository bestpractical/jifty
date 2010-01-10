#!/usr/bin/env perl
use strict;
use warnings;
use Jifty::Test::Dist;
use Jifty::Test::WWW::Mechanize;

plan tests => 9;

my $server = Jifty::Test->make_server;
isa_ok( $server, 'Jifty::TestServer' );
my $URL = $server->started_ok;

my $mech = Jifty::Test::WWW::Mechanize->new;
$mech->get_ok( $URL . '/' , "testing template declare buffer" );
$mech->content_contains( '<html xmlns' );
$mech->content_contains( '<head title="tdpage_test">' , "find page header" );
$mech->content_contains( '</head>' );
$mech->content_contains( '<body>' , "find page body" );
$mech->content_contains( '<h2>TDPAGE</h2>');
$mech->content_contains( '</body>'  );
