package Jifty::Plugin::SetupWizard::View::Generic;
use strict;
use warnings;
use Jifty::View::Declare -base;
use base qw/ Jifty::Plugin::SetupWizard::View::Helpers /;

template 'index.html' => page {
    my $appname = Jifty->config->framework('ApplicationName');
    h1 { _("Welcome to %1!", $appname) };

    render_region(
        name      => 'WizardStep',
        path      => "/__jifty/admin/setupwizard/step",
        arguments => {
            step => 0,
        },
    );
};

template 'step' => sub {
    my $self = shift;
    my $step = get('step');
    my $steps = Jifty->find_plugin('Jifty::Plugin::SetupWizard')->steps;
    my $step_info = $steps->[$step] or die "Invalid step index";

    div {
        class is 'setupwizard-step';

        form {
            h3 { _('%1. %2', $step+1, $step_info->{header}) } if $step_info->{header};

            show $step_info->{template};

            unless ($step_info->{hide_button}) {
                form_submit(
                    label => _('Next'),
                    onclick => {
                        # Submit all actions
                        submit => undef,

                        # Advance to the next step
                        refresh_self => 1,
                        arguments => {
                            step => $step + 1,
                        },
                    },
                );
            }
        };
    };

    div {
        class is 'setupwizard-links';

        span { 'Skip to: ' };

        for my $i (0 .. @$steps - 1) {
            # Separator
            if ($i > 0) {
                span { ' | ' }
            }

            step_link(
                index   => $i,
                label   => "%1",
                current => $i == $step,
            );
        }
    };
};

sub step_link {
    my %args = (
        index   => 0,
        label   => "%1",
        current => 0,
        @_,
    );

    my $index = $args{index};

    my $steps = Jifty->find_plugin('Jifty::Plugin::SetupWizard')->steps;
    return unless $index >= 0 && $index < @$steps;

    my $info = $steps->[$index];
    my $name = $info->{link} || $info->{header} || $info->{template};

    if ($args{current}) {
        b { _($args{label}, $name) },
    }
    else {
        hyperlink(
            label => _($args{label}, $name),
            onclick => {
                replace_self => 1,
                arguments => {
                    step => $index,
                },
            },
        );
    }
}

template 'welcome' => sub {
    my $self = shift;
    my $appname = Jifty->config->framework('ApplicationName');

    p {
        _("This installer will help you configure %1 by walking you through the following steps.", $appname)
    }

    ol {
        for my $i (0 .. @{ Jifty->find_plugin('Jifty::Plugin::SetupWizard')->steps } - 1) {
            li {
                step_link(
                    index   => $i,
                    label   => "%1",
                    current => $i == get('step'),
                );
            }
        }
    }

    p {
        _("At any time you may close the wizard; your progress will be saved for next time. You may also skip around, doing these steps in whatever order suits you.");
    }

    p {
        outs_raw _("This setup wizard was activated by the presence of <tt>SetupMode: 1</tt> in one of your configuration files. If you are seeing this erroneously, you may restore normal operation by adjusting the <tt>etc/site_config.yml</tt> file to have <tt>SetupMode: 0</tt> set under <tt>framework</tt>.");
    };

    form_submit(
        label => _('Begin'),
        onclick => {
            # Advance to the next step
            refresh_self => 1,
            arguments => {
                step => get('step') + 1,
            },
        },
    );
};

template 'language' => sub {
    p { _("You may select a different language.") };
};

template 'database' => sub {
    my $self = shift;
    my $appname = Jifty->config->framework('ApplicationName');

    p { _("You may choose a database engine.") };

    p { _("%1 works with a number of different databases. MySQL, PostgreSQL, and SQLite are all supported. You should choose the database that you or your local database administrator knows best.", $appname) };

    p { _("SQLite is a small database engine that does not need a server or any configuration. We recommend it for testing, demonstration, and development, but it is not quite right for a high-volume production server.") };

    p { _("MySQL and PostgreSQL are well-supported production-quality database engines. ") };

    show 'database_widget';
};

template 'web' => sub {
    my $self = shift;
    p { _("You may change web server settings.") };

    my $appname = lc Jifty->config->framework('ApplicationName');
    $appname =~ s/-//g;

    $self->config_field(
        field      => 'BaseURL',
        context    => '/framework/Web',
        value_args => {
            hints => _('The root URL for the web server (examples: http://%1.yourcompany.com, http://business.com/%1)', $appname),
        },
    );

    $self->config_field(
        field   => 'Port',
        context => '/framework/Web',
    );
};

template 'finalize' => sub {
    my $self = shift;
    p { _("You may finalize your configuration.") };

    my $appname = Jifty->config->framework('ApplicationName');
    my $action = $self->config_field(
        field      => 'SetupMode',
        context    => '/framework',
        message    => _('Setup finished. Welcome to %1!', $appname),
        value_args => {
            render_as     => 'hidden',
            default_value => 0,
        },
    );

    form_next_page url => '/';
    form_submit( label => _('Done!') );
};

1;

__END__

=head1 NAME

Jifty::Plugin::SetupWizard::View::Generic - generic templates for SetupWizard

=cut

