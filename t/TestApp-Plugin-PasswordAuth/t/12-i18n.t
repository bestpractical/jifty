#!/usr/bin/env perl
use warnings;
use strict;

=head1 DESCRIPTION

Basic tests for I18N.

=cut

use Jifty::Test::Dist tests => 7, l10n => 1;
use Jifty::Test::WWW::Mechanize;

use Encode 'decode';
use utf8;
use LWP::UserAgent;


my $server = Jifty::Test->make_server;
isa_ok($server, 'Jifty::Server');

my $URL = $server->started_ok;
my $mech = Jifty::Test::WWW::Mechanize->new();

$mech->get_ok("$URL/login","Got login page");

my $res;

$mech->default_header('Accept-Language' => "en");
$res = $mech->get("$URL/login");
ok $res->is_success, "can access login page";
like $res->content, qr/Lost your password/, 'en works';

$mech->default_header('Accept-Language' => "fr");
$res = $mech->get("$URL/login");
ok $res->is_success, "can access login page";
like adjust($res->content), qr/oublié/,'fr login works';

sub adjust {
    my $s = shift;
    $s = decode('UTF-8', $s);
    $s =~ s/<.*?>//gs;
    $s =~ s/\s+/ /gs;
    #$s =~ s/\W+//g;
    #$s =~ s/\d+//g;
    $s;
}

