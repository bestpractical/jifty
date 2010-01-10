#!/usr/bin/env perl
use lib 't/TestApp-Plugin-SetupWizard/lib';
use TestApp::Plugin::SetupWizard::Test tests => 14;

my $server = Jifty::Test->make_server;

isa_ok($server, 'Jifty::TestServer');

my $URL  = $server->started_ok;
my $mech = Jifty::Test::WWW::Mechanize->new();

$mech->get_ok("$URL", "Got the doc root");
site_config_is(undef, 'no site config to begin with');

$mech->content_like(qr/This installer will help you configure TestApp-Plugin-SetupWizard/, "got setup wizard on load");
$mech->click_button(value => "Begin");
site_config_is(undef, 'no site config yet');

$mech->content_like(qr/choose a database engine/, "step 1: database");
$mech->click_button(value => "Next");
site_config_is({
    framework => {
        Database => {
            Database => Jifty->config->framework('Database')->{Database},
            Driver => 'SQLite',
        },
    },
}, 'Database defaults now written to site_config');

$mech->content_like(qr/web server settings/, "step 2: server");
$mech->click_button(value => "Next");
site_config_is({
    framework => {
        Database => {
            Database => Jifty->config->framework('Database')->{Database},
            Driver => 'SQLite',
        },
        Web => {
            BaseURL => 'http://localhost',
            Port    => Jifty->config->framework('Web')->{Port},
        },
    },
}, 'Web-specific defaults');

$mech->content_like(qr/finalize your config/, "step 3: finalize");
$mech->click_button(value => "Done!");
site_config_is({
    framework => {
        Database => {
            Database => Jifty->config->framework('Database')->{Database},
            Driver => 'SQLite',
        },
        Web => {
            BaseURL => 'http://localhost',
            Port    => Jifty->config->framework('Web')->{Port},
        },
        SetupMode => 0,
    },
}, 'SetupMode is done, so it is now 0');
$mech->content_like(qr/Setup finished. Welcome to TestApp-Plugin-SetupWizard!/, "setup tells us we're finished");
$mech->content_like(qr/You said you wanted a pony/, "we're on the regular homepage");

