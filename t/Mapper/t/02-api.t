#!/usr/bin/env perl

use warnings;
use strict;

=head1 DESCRIPTION

Continuations tests

=cut

use Jifty::Test::Dist tests => 13;

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

# Feeding the first action into the second should cause both to run;
# first, test via setting arguments during action creation (which sets
# sticky values)
$mech->form_number(2);
$mech->submit_form_ok;
$mech->content_like(qr/got the grail/i, "Got the grail");
$mech->content_like(qr/crossed the bridge/i, "And crossed the bridge");

# Tests for proper generation of default "name" parameter to
# argument_of and result_to
$mech->content_unlike(qr/R`[^']+`J:A:F/, "Doesn't have full argument name");
$mech->content_like(qr/J:A:F-castle-(\S+): Aaaaaargh/, "Has the right value name");

# And then, the same, but via default_values on the form field
$mech->form_number(3);
$mech->submit_form_ok;
$mech->content_like(qr/got the grail/i, "Got the grail");
$mech->content_like(qr/crossed the bridge/i, "And crossed the bridge");
