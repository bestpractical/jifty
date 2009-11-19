#!/usr/bin/env perl
use warnings;
use strict;

use Jifty::Test::Dist tests => 6;
use Jifty::Test::WWW::Mechanize;

my $server = Jifty::Test->make_server;
my $url = $server->started_ok;

my $mech = Jifty::Test::WWW::Mechanize->new;
$mech->get_ok( $url, 'grab a page' );

my $css_page = '';
if ( $mech->content =~ qr{type="text/css" href="(.*?)"} ) {
    $css_page = $1;
}


$mech->content_like(qr'<form id="inmenu"');

ok($css_page, "Got a link to the CSS page");
$mech->get_ok($url.$css_page, "Got the CSS");
is($mech->content_type, 'text/css', "the css file is served out with the right content type");

