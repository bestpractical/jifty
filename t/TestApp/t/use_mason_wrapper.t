#!/usr/bin/env perl
use warnings;
use strict;

use Jifty::Test::Dist tests => 7;
use Jifty::Test::WWW::Mechanize;

my $server = Jifty::Test->make_server;
my $url = $server->started_ok;

my $mech = Jifty::Test::WWW::Mechanize->new;
$mech->get_ok( $url . '/use_mason_wrapper', 'grab a page' );

$mech->content_contains( 'In a Mason Wrapper?', 'got the right template' );
$mech->content_contains( 'Custom Wrapper', 'used the custom wrapper' );

$mech->get_ok( $url . '/_elements/wrapper', 'getting the wrapper directly');
$mech->content_contains( 'Something went awry', 'and we were not able to');
$mech->warnings_like(qr/Unhandled web error/);
