use strict;
use warnings;
use lib 't/lib';
use Jifty::SubTest;
use Jifty::Test tests => 6;
use Jifty::Test::WWW::Selenium;
use utf8;

my $server  = Jifty::Test->make_server;
my $sel = Jifty::Test::WWW::Selenium->rc_ok( $server );
my $URL = $server->started_ok;

$sel->open_ok("/onclick.html");
$sel->click_ok("//a[\@id='replace_content']");

my $html = $sel->get_html_source;

like( $html, qr/yatta/, 'replace content correctly' );
unlike( $html, qr{args:/content1\.html}, 'replaced by javascript' );

$sel->stop;

