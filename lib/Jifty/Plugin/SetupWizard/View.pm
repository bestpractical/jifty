package Jifty::Plugin::SetupWizard::View;
use strict;
use warnings;
use Jifty::View::Declare -base;

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
    my $steps = Jifty->find_plugin('Jifty::Plugin::SetupWizard')->steps;
    my $step_info = $steps->[$step] or abort(400);

    div {
        class is 'setupwizard-step';

        form {
            h3 { $step_info->{header} } if $step_info->{header};

            show "/__jifty/admin/setupwizard/$step_info->{template}";
            my @actions = keys %{ Jifty->web->form->actions };
            form_submit(
                label => _('Save'),
                onclick => [
                    {
                        submit => \@actions,
                    },
                    {
                        replace_self => 1,
                        arguments => {
                            step => $step + 1,
                        },
                    },
                ],
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

    for my $field (qw/field context target_file/) {
        outs_raw($action->form_field(
            $field,
            render_as => 'hidden',
            (exists($args{$field}) ? (default_value => $args{$field}) : ()),
        ));
    }
}

template '/__jifty/admin/setupwizard/language' => sub {
    p { _("You may select a different language.") };
};

template '/__jifty/admin/setupwizard/database' => sub {
    p { _("You may choose a database engine.") };

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

    config_field(
        field      => 'Driver',
        context    => '/framework/Database',
        value_args => {
            label            => 'Database Engine',
            render_as        => 'select',
            available_values => [
                { display => 'SQLite',     value => 'SQLite' },
                { display => 'MySQL',      value => 'mysql' },
                { display => 'PostgreSQL', value => 'Pg' },
            ],
            onchange => [$onchange],
        },
    );

    config_field(
        field      => 'Database',
        context    => '/framework/Database',
        value_args => {
            label => 'Database Name',
        },
    );

    my $driver = Jifty->config->framework('Database')->{Driver};
    render_region(
        name => 'database_details',
        path => "/__jifty/admin/setupwizard/database/$driver",
    );
};

template '/__jifty/admin/setupwizard/database/SQLite' => sub {
    # Nothing more needed!
};

sub _configure_database_connectivity {
    config_field(
        field   => 'Host',
        context => '/framework/Database',
    );

    config_field(
        field   => 'User',
        context => '/framework/Database',
    );

    config_field(
        field   => 'Password',
        context => '/framework/Database',
    );
}

template '/__jifty/admin/setupwizard/database/mysql' => sub {
    _configure_database_connectivity;
};

template '/__jifty/admin/setupwizard/database/Pg' => sub {
    _configure_database_connectivity;
};

template '/__jifty/admin/setupwizard/web' => sub {
    p { _("You may change web server settings.") };

    config_field(
        field   => 'BaseURL',
        context => '/framework/Web',
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

