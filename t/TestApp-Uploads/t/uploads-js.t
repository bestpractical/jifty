#!/usr/bin/env perl
use warnings;
use strict;
use Jifty::Test::Dist tests => 9;
use Jifty::Test::WWW::Selenium;

my $server = Jifty::Test->make_server;
isa_ok( $server, 'Jifty::Server' );
my $URL = $server->started_ok;
my $sel = Jifty::Test::WWW::Selenium->rc_ok($server);

$sel->open_ok("/uploads.html");
my $field = '//a[contains(@class, "attach-more")]';
$sel->wait_for_element_present_ok($field);
my $src = $sel->get_html_source();
my $count = () = $src =~ /type="file"/g;
is( $count, 1, 'initially, only 1 file' );
$sel->click_ok($field);
$sel->wait_for_element_present_ok($field);
$src = $sel->get_html_source();
$count = () = $src =~ /type="file"/g;
is( $count, 2, 'got 2 files' );

$sel->stop;
