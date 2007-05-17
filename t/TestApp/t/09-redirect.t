#!/usr/bin/env perl

use warnings;
use strict;

=head1 DESCRIPTION

If we do a redirect in a 'before' in the dispatcher, actions should
still get run.

=cut

use lib 't/lib';
use Jifty::SubTest;
use Jifty::Test tests => 6;
use Jifty::Test::WWW::Mechanize;

my $server  = Jifty::Test->make_server;

isa_ok($server, 'Jifty::Server');

my $URL     = $server->started_ok;
my $mech    = Jifty::Test::WWW::Mechanize->new();

$mech->get_ok("$URL/manual_redirect", "Got redirect");

$mech->fill_in_action_ok('go', url => $URL."/index.html");
$mech->submit_html_ok();
like($mech->uri, qr|/index.html|, "At index");

1;

