package Jifty::Plugin::SetupWizard::View;
use strict;
use warnings;
use Jifty::View::Declare -base;

template '/__jifty/admin/setupwizard' => page {
    my $appname = Jifty->config->framework('ApplicationName');
    h1 { _("Welcome to %1!", $appname) };

    render_region(
        name      => 'WizardStep',
        path      => "/__jifty/admin/setupwizard/step",
        arguments => {
            step => 0,
        },
    );

    p { _("You're seeing this configuration because you started %1 in AdminMode and the SetupWizard plugin. Disable one or both of these to restore normal operation.", $appname) };
};

template '/__jifty/admin/setupwizard/step' => sub {
    my $step = get('step');
    my $steps = Jifty->find_plugin('Jifty::Plugin::SetupWizard')->steps;
    my $step_info = $steps->[$step] or abort(400);

    div {
        class is 'setupwizard-step';

        form {
            h3 { $step_info->{header} } if $step_info->{header};

            show "/__jifty/admin/setupwizard/$step_info->{template}";
            form_submit(
                label => _('Save'),
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
        };
    };

    div {
        class is 'setupwizard-links';
        step_link(
            index => $step - 1,
            label => "Back: %1",
        );
        br {};
        step_link(
            index => $step + 1,
            label => "Skip to: %1",
        );
    };
};

sub step_link {
    my %args = (
        index => 0,
        label => "%1",
        @_,
    );

    my $index = $args{index};

    my $steps = Jifty->find_plugin('Jifty::Plugin::SetupWizard')->steps;
    return unless $index >= 0 && $index < @$steps;

    my $info = $steps->[$index];
    my $name = $info->{link} || $info->{header} || $info->{template};

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

sub config_field {
    my %args = @_;

    my $action = new_action('AddConfig');

    my %value_args = %{ $args{value_args} || {} };

    # Grab a sensible default, the current value of config
    if (!exists($value_args{default_value})) {
        $value_args{default_value} = Jifty->config->contextual_get($args{context}, $args{field});
    }

    # Grab sensible label, the value of field
    if (!exists($value_args{label})) {
        $value_args{label} = $args{field};
    }

    outs_raw($action->form_field('value' => %value_args));

    for my $field (qw/field context target_file empty_is_undef/) {
        outs_raw($action->form_field(
            $field,
            render_as => 'hidden',
            (exists($args{$field}) ? (default_value => $args{$field}) : ()),
        ));
    }
}

template '/__jifty/admin/setupwizard/welcome' => sub {
    p { _("Hi!") };
};

template '/__jifty/admin/setupwizard/language' => sub {
    p { _("You may select a different language.") };
};

template '/__jifty/admin/setupwizard/database' => sub {
    # XXX: We've got to add a sane way to unquote stuff in onfoo handlers...
    my $onchange = 'Jifty.update('
                 . Jifty::JSON::objToJson({
                    actions          => {},
                    action_arguments => {},
                    fragments        => [
                        {
                            mode => 'Replace',
                            path => '/__jifty/admin/setupwizard/database/PLACEHOLDER',
                            region => Jifty->web->qualified_region('database_details'),
                        },
                    ],
                    continuation     => undef,

                 }, {singlequote => 1})
                 . ', this)';

    $onchange =~ s/PLACEHOLDER/'+this.value+'/;

    # Only show them drivers they have available
    my (@available_drivers, @unavailable_drivers);
    my @all_drivers = (
        { display => 'SQLite',     value => 'SQLite' },
        { display => 'MySQL',      value => 'mysql' },
        { display => 'PostgreSQL', value => 'Pg' },
        #{ display => 'Oracle', value => 'Oracle' },
    );
    for (@all_drivers) {
        if (Jifty->handle->is_available_driver($_->{value})) {
            push @available_drivers, $_;
        }
        else {
            push @unavailable_drivers, $_;
        }
    }

    my $current_driver = Jifty->config->framework('Database')->{Driver};
    my $appname = Jifty->config->framework('ApplicationName');

    p { _("You may choose a database engine.") };

    p { _("%1 works with a number of different databases. MySQL, PostgreSQL, and SQLite are all supported. You should choose the database that you or your local database administrator knows best.", $appname) };

    p { _("SQLite is a small database engine that does not need a server or any configuration. We recommend it for testing, demonstration, and development, but it is not quite right for a high-volume production server.") };

    p { _("MySQL and PostgreSQL are well-supported production-quality database engines. ") };

    if (@unavailable_drivers) {
        my @drivers = map { "DBD::$_->{value}" } @unavailable_drivers;
        my $drivers = join ', ', @drivers;

        $drivers =~ s/, (?!.*,)/ or /;

        p { _("If your preferred database is not listed in the dropdown below, that means we could not find a database driver for it. You may be able to remedy this by using CPAN to download and install $drivers.") };
    }

    config_field(
        field      => 'Driver',
        context    => '/framework/Database',
        value_args => {
            label            => _('Database Engine'),
            render_as        => 'select',
            available_values => \@available_drivers,
            onchange         => [$onchange],
        },
    );

    config_field(
        field      => 'Database',
        context    => '/framework/Database',
        value_args => {
            label     => _('Database Name'),
        },
    );

    render_region(
        name => 'database_details',
        path => "/__jifty/admin/setupwizard/database/$current_driver",
    );

    render_region(
        name => 'test_connectivity',
        path => '/__jifty/admin/setupwizard/database/test_connectivity_button',
    );
};

template '/__jifty/admin/setupwizard/database/SQLite' => sub {
    # Nothing more needed!
};

sub _configure_database_connectivity {
    my $driver = shift;

    config_field(
        field   => 'Host',
        context => '/framework/Database',
        value_args => {
            hints => _('The domain name of your database server (for example, db.example.com)'),
        },
        empty_is_undef => 1,
    );

    config_field(
        field   => 'Port',
        context => '/framework/Database',
        value_args => {
            hints => _('Leave blank to use the default value for your database'),
        },
        empty_is_undef => 1,
    );

    # Better default for postgres ("root" is Jifty's current default)
    my %user_value_args;
    $user_value_args{default_value} = 'postgres'
        if $driver eq 'Pg'
        && Jifty->config->framework('Database')->{User} eq 'root';

    config_field(
        field   => 'User',
        context => '/framework/Database',
        empty_is_undef => 1,
        value_args => \%user_value_args,
    );

    config_field(
        field   => 'Password',
        context => '/framework/Database',
        value_args => {
            render_as => 'password',
        },
        empty_is_undef => 1,
    );
}

template '/__jifty/admin/setupwizard/database/mysql' => sub {
    _configure_database_connectivity('mysql');
};

template '/__jifty/admin/setupwizard/database/Pg' => sub {
    _configure_database_connectivity('Pg');

    config_field(
        field   => 'RequireSSL',
        context => '/framework/Database',
        value_args => {
            label     => _('Use SSL?'),
            render_as => 'checkbox',
        },
    );
};

template '/__jifty/admin/setupwizard/database/test_connectivity_button' => sub {
    hyperlink(
        label     => _("Test connectivity"),
        as_button => 1,
        onclick   => {
            # Submit all actions
            submit => undef,

            # Actually test connectivity
            replace_with => '/__jifty/admin/setupwizard/database/test_connectivity',
        },
    );
};

template '/__jifty/admin/setupwizard/database/test_connectivity' => sub {
    my $action = Jifty::Plugin::SetupWizard::Action::TestDatabaseConnectivity->new;
    $action->validate;
    $action->run;

    if ($action->result->success) {
        p {
            attr { class => 'popup_message' };
            outs $action->result->message;
        }
    }
    else {
        p {
            attr { class => 'popup_error' };
            outs $action->result->error;
        }
    }

    show '/__jifty/admin/setupwizard/database/test_connectivity_button';
};

template '/__jifty/admin/setupwizard/web' => sub {
    p { _("You may change web server settings.") };

    my $appname = lc Jifty->config->framework('ApplicationName');
    $appname =~ s/-//g;

    config_field(
        field      => 'BaseURL',
        context    => '/framework/Web',
        value_args => {
            hints => _('The root URL for the web server (examples: http://%1.yourcompany.com, http://business.com/%1)', $appname),
        },
    );

    config_field(
        field   => 'Port',
        context => '/framework/Web',
    );
};

template '/__jifty/admin/setupwizard/finalize' => sub {
    p { _("You may finalize your configuration.") };
};

1;

__END__

=head1 NAME

Jifty::Plugin::SetupWizard::View - templates for SetupWizard

=head1 FUNCTIONS

=head2 step_link

A helper function for constructing a link to a different step. Expected
arguments: the C<index> of the step and the C<label> for the link.

=head2 config_field

A helper function for constructing a mini-form for a config field. Expected
arguments are:

=over 4

=item value_args

The arguments for the C<form_field> call for value. If there's no C<default_value>, one will be constructed using the C<context> parameter.

=item field

=item context

=item target_file

These parameters are for specifying defaults for each action argument.

=back

=cut

