use strict;
use warnings;
use Jifty::Test::Dist tests => 6, actual_server => 1;
use Jifty::Test::WWW::Selenium;
use utf8;

my $server  = Jifty::Test->make_server;
my $sel = Jifty::Test::WWW::Selenium->rc_ok( $server );
my $URL = $server->started_ok;
diag $URL;

$sel->open_ok("/");
$sel->select_ok("foo", "label=4");
$sel->click_ok("//input[\@value='Next']");

my $html = $sel->get_html_source;

unlike($html, qr'name="J:V-region-__page."');
diag $html;

$sel->stop;

#$SIG{INT} = sub { exit };

#sleep 100 while 1;


exit;
__END__
$sel->value_is("J:A:F-name-create_user", "4");
$sel->type_ok("J:A:F-email-create_user", "orz\@orz.org");
$sel->open_ok("/");
$sel->select_ok("foo", "label=4");
$sel->click_ok("//input[\@value='Next']");
$sel->value_is("J:A:F-name-create_user", "4");
$sel->type_ok("J:A:F-email-create_user", "orz\@orz.org");
