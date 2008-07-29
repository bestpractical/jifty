#!/usr/bin/env perl

use warnings;
use strict;

=head1 DESCRIPTION

Tests that error pages work

=cut

use Jifty::Test::Dist tests => 10;
use Jifty::Test::WWW::Mechanize;

ok(1, "Loaded the test script");

my $server = Jifty::Test->make_server;
isa_ok( $server, 'Jifty::Server' );
my $URL = $server->started_ok;

my $mech = Jifty::Test::WWW::Mechanize->new;
$mech->get_ok("$URL/template-with-error");
$mech->base_like(qr/mason_internal_error/);
$mech->content_like(qr/locate object method .*?non_existant_method.*?/);
$mech->content_like(qr/template-with-error line 5/);

ok($mech->continuation, "Have a continuation");
ok($mech->continuation->response->error, "Have an error set");
isa_ok($mech->continuation->response->error, "HTML::Mason::Exception", "Error is a reference");

1;

