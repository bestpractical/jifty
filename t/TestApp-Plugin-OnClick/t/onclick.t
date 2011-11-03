use strict;
use warnings;
use Jifty::Test::Dist tests => 10, actual_server => 1;
use Jifty::Test::WWW::Selenium;
use utf8;

my $server = Jifty::Test->make_server;
my $sel    = Jifty::Test::WWW::Selenium->rc_ok($server);
my $URL    = $server->started_ok;

$sel->open_ok("/onclick.html");
$sel->click_ok("//a[\@id='replace_content']");

sleep 2; # in case the click returning slowly

my $html = $sel->get_html_source;


like( $html, qr/yatta/, 'replace content correctly' );
unlike( $html, qr{args:/content1\.html}, 'replaced by javascript' );

$sel->click_ok("//a[\@id='original_content']");
sleep 2; # in case the click returning slowly
is( $sel->get_alert,
    'please use Jifty.update instead of update.',
    'bare update is deprecated'
);

sleep 2;

$html = $sel->get_html_source;

like( $html, qr/original content/, 'replace content correctly' );
unlike( $html, qr{args:/content\.html}, 'replaced by javascript' );

$sel->stop;

