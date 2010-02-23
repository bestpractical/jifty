#!/usr/bin/env perl

use warnings;
use strict;

=head1 DESCRIPTION

If we do a redirect in a 'before' in the dispatcher, actions should
still get run.

=cut

BEGIN {chdir "t/TestApp"}
use lib '../../lib';
use Jifty::Test tests => 6;
use Jifty::Test::WWW::Mechanize;

my $server  = Jifty::Test->make_server;

isa_ok($server, 'Jifty::TestServer');

my $URL     = $server->started_ok;
my $mech    = Jifty::Test::WWW::Mechanize->new();

$mech->get_ok("$URL/redirect", "Got redirect");
like($mech->uri, qr|/index.html|, "At index");
ok($mech->continuation,"We have a continuation");
$mech->content_like(qr/Something happened/, "Action ran");

1;

