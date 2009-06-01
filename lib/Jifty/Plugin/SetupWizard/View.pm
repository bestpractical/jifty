package Jifty::Plugin::SetupWizard::View;
use strict;
use warnings;
use Jifty::View::Declare -base;

my @steps = (
    'language',
    'database',
);

template '/__jifty/admin/setupwizard' => page {
    my $appname = Jifty->config->framework('ApplicationName');
    h1 { "Welcome to $appname!" };

    render_region(
        name      => 'WizardStep',
        path      => "/__jifty/admin/setupwizard/step",
        arguments => {
            step => 0,
        },
    );

    p { _("You're seeing this configuration because you started $appname in AdminMode and the SetupWizard plugin. Disable one or both of these to restore normal operation.") };
};

template '/__jifty/admin/setupwizard/step' => sub {
    my $step = get('step');
    my $name = $steps[$step] or abort(400);

    show "/__jifty/admin/setupwizard/$name";

    if ($step > 0) {
        hyperlink(
            label => _("Back: %1", $steps[$step - 1]),
            onclick => {
                replace_self => 1,
                arguments => {
                    step => $step - 1,
                },
            },
        );
    }

    if ($step < @steps - 1) {
        hyperlink(
            label => _("Skip: %1", $steps[$step + 1]),
            onclick => {
                replace_self => 1,
                arguments => {
                    step => $step + 1,
                },
            },
        );
    }
};

template '/__jifty/admin/setupwizard/language' => sub {
    h3 { "Choose a Language" };
    p { _("You may select a different language.") };
};

template '/__jifty/admin/setupwizard/database' => sub {
    h3 { "Database" };
    p { _("You may choose a database engine.") };
};

1;

