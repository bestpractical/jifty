#!/usr/bin/perl

use warnings;
use strict;

=head1 DESCRIPTION

This is a template for your own tests. Copy it and modify it.

=cut

BEGIN {chdir "t/Continuations"}
use lib '../../lib';
use Jifty::Test no_plan => 1;

use_ok('Jifty::Test::WWW::Mechanize');

my $server = Jifty::Test->make_server;
my $URL = $server->started_ok;
my $mech = Jifty::Test::WWW::Mechanize->new;

$mech->get($URL . '/help');
like($mech->uri, qr'index-help\.html', '/help redirected to /index-help.html');
$mech->content_contains('getting help', 'before blocks got run properly');

1;

