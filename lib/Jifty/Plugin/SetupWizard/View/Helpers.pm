package Jifty::Plugin::SetupWizard::View::Helpers;
use strict;
use warnings;
use Jifty::View::Declare -base;

=head1 NAME

Jifty::Plugin::SetupWizard::View::Helpers - Helper templates and functions for SetupWizard

=head1 TEMPLATES

=head2 database_widget

Provides a simple database configuration widget

=cut

private template 'database_widget' => sub {
    my $self = shift;
    # XXX: We've got to add a sane way to unquote stuff in onfoo handlers...
    my $onchange = 'Jifty.update('
                 . Jifty::JSON::encode_json({
                    actions          => {},
                    action_arguments => {},
                    fragments        => [
                        {
                            mode => 'Replace',
                            path => $self->fragment_for('database_widget/PLACEHOLDER'),
                            region => Jifty->web->qualified_region('database_details'),
                        },
                    ],
                    continuation     => undef,

                 })
                 . ', this)';

    $onchange =~ s/PLACEHOLDER/"+this.value+"/;

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

    if (@unavailable_drivers) {
        show 'database_widget/unavailable_drivers', @unavailable_drivers;
    }

    my $current_driver = Jifty->config->framework('Database')->{Driver};

    $self->config_field(
        field      => 'Driver',
        context    => '/framework/Database',
        value_args => {
            label            => _('Database Engine'),
            render_as        => 'select',
            available_values => \@available_drivers,
            onchange         => [$onchange],
        },
    );

    $self->config_field(
        field      => 'Database',
        context    => '/framework/Database',
        value_args => {
            label     => _('Database Name'),
        },
    );

    render_region(
        name => 'database_details',
        path => $self->fragment_for("database_widget/$current_driver"),
    );

    render_region(
        name => 'test_connectivity',
        path => $self->fragment_for("database_widget/test_connectivity"),
    );
};

private template 'database_widget/unavailable_drivers' => sub {
    my $self = shift;
    my $databases = join ', ', map { $_->{display} } @_;
    my $drivers   = join ', ', map { "DBD::$_->{value}" } @_;

    $databases =~ s/, (?!.*,)/ and /;
    $drivers   =~ s/, (?!.*,)/ or /;

    p { _("%quant(%1,%2 is,%2 are) also supported, but we couldn't find the database %quant(%1,driver,drivers). You may be able to remedy this by installing %3 from CPAN.", scalar @_, $databases, $drivers) };
};

private template 'database_widget/configure_connectivity' => sub {
    my $self   = shift;
    my $driver = shift;

    $self->config_field(
        field   => 'Host',
        context => '/framework/Database',
        value_args => {
            hints => _('The host name of your database server (for example, localhost or db.example.com)'),
        },
        empty_is_undef => 1,
    );

    $self->config_field(
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

    $self->config_field(
        field   => 'User',
        context => '/framework/Database',
        empty_is_undef => 1,
        value_args => \%user_value_args,
    );

    $self->config_field(
        field   => 'Password',
        context => '/framework/Database',
        value_args => {
            render_as => 'password',
        },
        empty_is_undef => 1,
    );
};

template 'database_widget/SQLite' => sub {
    # Nothing more needed!
};

template 'database_widget/mysql' => sub {
    show configure_connectivity => 'mysql';
};

template 'database_widget/Pg' => sub {
    my $self = shift;
    show configure_connectivity => 'Pg';

    $self->config_field(
        field   => 'RequireSSL',
        context => '/framework/Database',
        value_args => {
            label     => _('Require SSL?'),
            render_as => 'checkbox',
        },
    );
};

template 'database_widget/test_connectivity' => sub {
    my $self = shift;

    my $action = new_action(
        class   => 'Jifty::Plugin::SetupWizard::Action::TestDatabaseConnectivity',
        moniker => 'test-db-connectivity',
        order   => 100, # after everything else
    );

    if ( my $result = Jifty->web->response->result('test-db-connectivity') ) {
        p {{ class is 'test-connectivity-result' };
            if ($result->success) {
                outs $result->message;
            }
            else {
                outs $result->error;
            }
        };
    }

    $action->button(
        label     => _("Test connectivity"),
        onclick   => {
            # Submit all actions, which will be the database config actions and
            # then the connectivity test.
            submit => undef,
            refresh_self => 1,
        },
        # We need to register the action since we're not providing any arguments
        register  => 1,
    );

};


=head1 FUNCTIONS

=head2 config_field

A helper function for constructing a mini-form for a config field. It returns
the action that was created. Expected arguments are:

=over 4

=item value_args

The arguments for the C<form_field> call for value. If there's no C<default_value>, one will be constructed using the C<context> parameter.

=item field

=item context

=item target_file

=item message

=item empty_is_undef

These parameters are for specifying defaults for each action argument.

=back

=cut

sub config_field {
    my $self = shift;
    my %args = @_;

    my $moniker = $args{context} || Jifty->web->serial;
    $moniker =~ s{^/}{addconfig-}g;
    $moniker =~ s{/}{-}g;
    $moniker .= "-$args{field}";

    my $action = new_action(
        class   => 'AddConfig',
        moniker => $moniker,
        order   => 50,
        %{ $args{action_args} || {} }
    );

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

    for my $field (qw/field context target_file message empty_is_undef/) {
        outs_raw($action->form_field(
            $field,
            render_as => 'hidden',
            (exists($args{$field}) ? (default_value => $args{$field}) : ()),
        ));
    }

    return $action;
}

=head2 fragment_for PATH

Returns an absolute version of the relative path provided for use with regions.

=cut

sub fragment_for {
    my $self = shift;
    my $frag = shift;
    return $frag if $frag =~ /^\//;

    my $base = current_base_path();
    $base = "/$base" unless $base =~ /^\//;
    return "$base/$frag";
}

1;

