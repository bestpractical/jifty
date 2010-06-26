use strict;
use warnings;
use Jifty::Test::Dist tests => 7;
use Jifty::Test::WWW::Mechanize;

my $server  = Jifty::Test->make_server;
my $URL = $server->started_ok;
my $mech = Jifty::Test::WWW::Mechanize->new();

$mech->get_ok("$URL/static/css/main.css","Got main.css");
$mech->content_contains('@import "combobox.css"');
$mech->get_ok("$URL");
ok($mech->content =~ m{<link rel="stylesheet" type="text/css" href="(.*)" /});
my $css_file = $1;

$mech->get_ok($1);
$mech->content_contains('End of combobox.css', 'squished');

