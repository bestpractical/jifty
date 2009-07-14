package TestApp::Plugin::SetupWizard::Dispatcher;
use Jifty::Dispatcher -base;

on qr{^/$} => run {
    if (Jifty->config->framework('SetupMode')) {
        Jifty->find_plugin('Jifty::Plugin::SetupWizard')
            or die "The SetupWizard plugin needs to be used with SetupMode";

        show '/__jifty/admin/setupwizard';
    }
};

1;

