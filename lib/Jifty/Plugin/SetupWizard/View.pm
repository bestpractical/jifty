package Jifty::Plugin::SetupWizard::View;
use strict;
use warnings;
use Jifty::View::Declare -base;

template '/__jifty/admin/setupwizard/entry' => page {
    h1 { "Welcome to " . Jifty->config->framework('ApplicationName') . "!" };
};

1;

