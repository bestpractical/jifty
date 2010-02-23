#!/usr/bin/env perl
use warnings;
use strict;

use Jifty::Test::Dist tests => 7;
use Test::WWW::Mechanize::PSGI;

my $mech = Test::WWW::Mechanize::PSGI->new(
    app => Jifty->handler->psgi_app );

$mech->get_ok("http://example.com/dispatch/protocol", "Got /dispatch/protocol");
$mech->content_contains("NOT HTTPS");
$mech->content_contains("normal");

$mech->get_ok("https://example.com/dispatch/protocol", "Got /dispatch/protocol");
$mech->content_contains("HTTPS");
$mech->content_lacks("NOT");
$mech->content_contains("normal");

