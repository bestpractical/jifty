#!/usr/bin/env perl

use warnings;
use strict;

=head1 DESCRIPTION

Regression test - ensure /signup provides the signup form

=cut

use Jifty::Test::Dist tests => 5;
use Jifty::Test::WWW::Mechanize;

my $server  = Jifty::Test->make_server;

isa_ok($server, 'Jifty::TestServer');

my $URL     = $server->started_ok;
my $mech    = Jifty::Test::WWW::Mechanize->new();
ok(1, "Loaded the test script");

my $signup_page = "$URL/signup";
$mech->get_ok($signup_page, "signup page exists");

use Data::Dumper;
ok ( $mech->moniker_for('TestApp::Plugin::PasswordAuth::Action::Signup'),
     'signup page includes the signup form');

1;
