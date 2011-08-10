#!/usr/bin/env perl

use warnings;
use strict;

=head1 DESCRIPTION

Tests for request mapper

=cut

use Jifty::Test::Dist tests => 32;
use_ok('Jifty::Test::WWW::Mechanize');

# Set up server
my $server = Jifty::Test->make_server;
my $URL = $server->started_ok;
my $mech = Jifty::Test::WWW::Mechanize->new;

# Check that the first page is as we expect it
$mech->get("$URL/");
$mech->content_like(qr/Get the holy grail/, "Start page has expected content");
$mech->content_unlike(qr/got the grail/, "Start page doesn't have output of run action");

# ..and that the action does what we think it does
$mech->get("$URL/index.html?J:A-grail=GetGrail");
$mech->content_like(qr/got the grail/, "Running the action produces the expected result");

#### Degenerate cases
$mech->get("$URL/index.html?J:M-foo=");
$mech->content_like(qr/foo: &#39;&#39;/, "Nothing shows up as the empty string");
$mech->content_unlike(qr/J:M-foo/, "Doesn't have mapping parameter");

$mech->get("$URL/index.html?J:M-foo=bar");
$mech->content_like(qr/foo: bar/, "String sets to value");
$mech->content_unlike(qr/J:M-foo/, "Doesn't have mapping parameter");


#### Flat arguments
$mech->get("$URL/index.html?J:M-foo=A`bar");
$mech->content_like(qr/foo: ~/, "Passing no parameter sets to undef");
$mech->content_unlike(qr/J:M-foo/, "Doesn't have mapping parameter");

$mech->get("$URL/index.html?J:M-foo=A`bar;bar=baz");
$mech->content_like(qr/foo: baz/, "Passing parameter sets to value");
$mech->content_unlike(qr/J:M-foo/, "Doesn't have mapping parameter");

$mech->get("$URL/index.html?J:M-foo=A`bar;bar=baz;bar=troz");
$mech->content_like(qr/bar: &#38;1\s*\n\s+- baz\n\s+- troz/, "Multiple parameters are list");
$mech->content_like(qr/foo: \*1/, "Multiple parameters are to same reference");
$mech->content_unlike(qr/J:M-foo/, "Doesn't have mapping parameter");


#### Action results
$mech->get("$URL/index.html?J:M-foo=R`grail`bar");
$mech->content_like(qr/foo: ~/, "Action doesn't exist, sets to undef");
$mech->content_unlike(qr/J:M-foo/, "Doesn't have mapping parameter");

$mech->get("$URL/index.html?J:M-foo=R`grail`bar;J:A-grail=GetGrail");
$mech->content_like(qr/foo: ~/, "Content name doesn't exist, sets to undef");
$mech->content_unlike(qr/J:M-foo/, "Doesn't have mapping parameter");

$mech->get("$URL/index.html?J:M-foo=R`grail`castle;J:A-grail=GetGrail");
$mech->content_like(qr/foo: Aaaaaargh/, "Content name exists, sets to value");
$mech->content_unlike(qr/J:M-foo/, "Doesn't have mapping parameter");


#### Action arguments
$mech->get("$URL/index.html?J:M-foo=A`bridge`bar");
$mech->content_like(qr/foo: ~/, "Action doesn't exist, sets to undef");
$mech->content_unlike(qr/J:M-foo/, "Doesn't have mapping parameter");

$mech->get("$URL/index.html?J:M-foo=A`bridge`bar;J:A-bridge=CrossBridge");
$mech->content_like(qr/foo: ~/, "Argument name doesn't exist, sets to undef");
$mech->content_unlike(qr/J:M-foo/, "Doesn't have mapping parameter");

$mech->get("$URL/index.html?J:M-foo=A`bridge`quest;J:A-bridge=CrossBridge");
$mech->content_like(qr/foo: ~/, "Argument is valid but missing, sets to undef");
$mech->content_unlike(qr/J:M-foo/, "Doesn't have mapping parameter");

$mech->get("$URL/index.html?J:M-foo=A`bridge`name;J:A-bridge=CrossBridge");
$mech->content_like(qr/foo: ~/, "Argument is valid with default_value but missing, sets to undef");
$mech->content_unlike(qr/J:M-foo/, "Doesn't have mapping parameter");

$mech->get("$URL/index.html?J:M-foo=A`bridge`quest;J:A-bridge=CrossBridge;J:A:F-quest-bridge=grail");
$mech->content_like(qr/foo: grail/, "Argument is valid, sets to submitted value");
$mech->content_unlike(qr/J:M-foo/, "Doesn't have mapping parameter");

1;

