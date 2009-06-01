package Jifty::Plugin::SetupWizard::View;
use strict;
use warnings;
use Jifty::View::Declare -base;

my @steps = (
    {
        template => 'language',
        header   => 'Choose a Language',
    },
    {
        template => 'database',
        header   => 'Database',
    },
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
    my $step_info = $steps[$step] or abort(400);

    div {
        class is 'setupwizard-step';

        h3 { $step_info->{header} } if $step_info->{header};
        show "/__jifty/admin/setupwizard/$step_info->{template}";
    };

    div {
        class is 'setupwizard-links';
        if ($step > 0) {
            my $prev = $steps[$step - 1];
            hyperlink(
                label => _("Back: %1", $prev->{link} || $prev->{header} || $prev->{template}),
                onclick => {
                    replace_self => 1,
                    arguments => {
                        step => $step - 1,
                    },
                },
            );
        }

        if ($step < @steps - 1) {
            my $next = $steps[$step + 1];
            hyperlink(
                label => _("Skip to: %1", $next->{link} || $next->{header} || $next->{template}),
                onclick => {
                    replace_self => 1,
                    arguments => {
                        step => $step + 1,
                    },
                },
            );
        }
    };
};

template '/__jifty/admin/setupwizard/language' => sub {
    p { _("You may select a different language.") };
};

template '/__jifty/admin/setupwizard/database' => sub {
    p { _("You may choose a database engine.") };
};

1;

