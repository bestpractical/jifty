#!/usr/bin/env perl
use warnings;
use strict;

use Jifty::Test::Dist tests => 20, l10n => 1;
use Jifty::Test::WWW::Mechanize;
use Net::HTTP;
use URI;

use Encode 'decode';
use utf8;
use LWP::UserAgent;
my $server  = Jifty::Test->make_server;

isa_ok($server, 'Jifty::Server');

my $base = URI->new($server->started_ok);


my $mech = Jifty::Test::WWW::Mechanize->new;
my $res;

$mech->default_header('Accept-Language' => "en");
$res = $mech->get("$base/__jifty/admin/");
ok $res->is_success, "can access admin console";
like $res->content, qr/Models/, 'en works';

$res = $mech->get("$base/concrete.html");
ok $res->is_success, "can access concrete";
like $res->content, qr/2 concrete mixers/, 'en works for an unknown string';

$res = $mech->get("$base/concrete2.html");
ok $res->is_success, "can access concrete";
like $res->content, qr/2 concrete mixers/, 'en works for an unknown string';

$mech->default_header('Accept-Language' => "ja");
$res = $mech->get("$base/__jifty/admin/");
ok $res->is_success, "can access admin console";
like adjust($res->content), qr/モデル/, 'ja works';

$res = $mech->get("$base/concrete.html");
ok $res->is_success, "can access concrete";
like $res->content, qr/2 concrete mixers/, 'ja works for an unknown string';

$res = $mech->get("$base/concrete2.html");
ok $res->is_success, "can access concrete";
like $res->content, qr/2 concrete mixers/, 'en works for an unknown string';

$mech->default_header('Accept-Language' => "fr");
$res = $mech->get("$base/__jifty/admin/");
ok $res->is_success, "can access admin console";
like adjust($res->content), qr/Modèles/, 'fr locale works';

$mech->default_header('Accept-Language' => "zh-cn");
$res = $mech->get("$base/__jifty/admin/");
ok $res->is_success, "can access admin console";
like adjust($res->content), qr/数据库/, 'zh-cn works';

$mech->default_header('Accept-Language' => "zh-tw");
$res = $mech->get("$base/__jifty/admin/");
ok $res->is_success, "can access admin console";
like adjust($res->content), qr/資料庫/, 'zh-tw works';

sub adjust {
    my $s = shift;
    $s = decode('UTF-8', $s);
    $s =~ s/<.*?>//gs;
    $s =~ s/\s+/ /gs;
    #$s =~ s/\W+//g;
    #$s =~ s/\d+//g;
    $s;
}
