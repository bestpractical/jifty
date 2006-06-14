#!/usr/bin/perl

use warnings;
use strict;

=head1 DESCRIPTION

Test the interactions between continuations and dispatcher BEFORE
blocks

=cut

BEGIN {chdir "t/Continuations"}
use lib '../../lib';
use Jifty::Test tests => 7;

use_ok('Jifty::Test::WWW::Mechanize');

my $server = Jifty::Test->make_server;
my $URL = $server->started_ok;
my $mech = Jifty::Test::WWW::Mechanize->new;

$mech->get($URL . '/tutorial');
like($mech->uri, qr'index-help\.html', '/tutorial redirected to /index-help.html');
$mech->follow_link_ok(text => 'Done');
like($mech->uri, qr'/tutorial', 'Continuation call worked properly');
$mech->content_contains('Congratulations', 'before blocks got run properly on continuation call');

$mech->get($URL . '/tutorial');
$mech->content_contains('Congratulations', 'before blocks got run properly');

1;

