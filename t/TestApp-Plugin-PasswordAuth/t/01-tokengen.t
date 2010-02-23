#!/usr/bin/env perl

use warnings;
use strict;

=head1 DESCRIPTION

This is a template for your own tests. Copy it and modify it.

=cut

use Jifty::Test::Dist tests => 5;
use Jifty::Test::WWW::Mechanize;

my $server  = Jifty::Test->make_server;

isa_ok($server, 'Jifty::TestServer');

my $URL     = $server->started_ok;
my $mech    = Jifty::Test::WWW::Mechanize->new();
ok(1, "Loaded the test script");

# {{{ Get token for logging in with a JS-based md5-hashed password
my $service='/__jifty/webservices/yaml';
$mech->post("$URL/$service", {"J:A-moniker" => "GeneratePasswordToken", "J:A:F-email-moniker" => 'gooduser@example.com'});

# XXX needs to be more precise in checking for the token, but this works
# as long as we're using time() for the token
$mech->content_like(qr/\d+/);

use Jifty::YAML;
my $data = Jifty::YAML::Load($mech->content);

my $token = $data->{'moniker'}->{'_content'}->{'token'};
my $salt = $data->{'moniker'}->{'_content'}->{'salt'};
like($salt, qr/^[0-9A-F]{8}$/i, 'Got a salt');

1;



