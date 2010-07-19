package Jifty::Plugin::SetupWizard::View::Helpers;
use strict;
use warnings;
use Jifty::View::Declare -base;

=head1 NAME

Jifty::Plugin::SetupWizard::View::Helpers - Helper templates and functions for SetupWizard

=head1 TEMPLATES

=head2 database_widget

Provides a database configuration and connectivity testing widget.

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
        message    => 'Set the database engine',
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
        message    => 'Set the database name',
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

    show 'database_widget/setup_new_database';
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
        message => 'Set the database server',
        value_args => {
            hints => _('The host name of your database server (for example, localhost or db.example.com)'),
        },
        empty_is_undef => 1,
    );

    $self->config_field(
        field   => 'Port',
        context => '/framework/Database',
        message => 'Set the database port',
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
        message => 'Set the database user',
        empty_is_undef => 1,
        value_args => \%user_value_args,
    );

    $self->config_field(
        field   => 'Password',
        context => '/framework/Database',
        message => 'Set the database password',
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
        message => 'Set the database to require SSL',
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
        order   => 60, # after everything else so far
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

    my @monikers = qw(test-db-connectivity);

    push @monikers, "addconfig-framework-Database-$_"
        for qw(Driver Database Host Port User Password RequireSSL);

    $action->button(
        label     => _("Test connectivity"),
        class     => 'test-db-connectivity',
        onclick   => {
            # We can't just submit all actions, because that will also send the restart action,
            # which we don't want for just testing the DB
            submit => \@monikers,
            refresh_self => 1,
        },
        # We need to register the action since we're not providing any arguments
        register  => 1,
    );

};

private template 'database_widget/setup_new_database' => sub {
    my $self = shift;

    my $action = Jifty->web->form->add_action(
        class   => 'Jifty::Plugin::SetupWizard::Action::SetupNewDatabase',
        moniker => 'setup-new-database',
        order   => 70, # After everything else in this widget,
                       # but it should be before any Restart actions.
    );
};

=head2 buttons [PARAMHASH]

Displays the appropriate buttons to go to the previous and next steps as
determined by the parameters.  See also L<steps>, L<step_after>, and
L<step_before>.

Valid keys for the PARAMHASH are:

=head3 for

Specify the step to show buttons for (i.e. the current step most often)

=head3 next and prev

Manually specify the name of the next or previous step

=head3 next_label and prev_label

Manually specify the labels of the next or previous buttons

=head3 restart

If true, a L<Jifty::Plugin::Config::Action::Restart> action is automatically
added to the next step button to run after all the other actions (order =
90).  This might be useful if you want to restart your app after setting some
config, but it's usually not necessary.

=cut

private template 'buttons' => sub {
    my $self = shift;
    my @args = @_;
    div {{ class is 'button-line' };
        show 'next_step_button', @args;
        show 'previous_step_button', @args;
    };
};

private template 'previous_step_button' => sub {
    my $self = shift;
    my %args = (
        prev_label => 'Previous step',
        @_
    );

    if ( defined $args{'for'} and not defined $args{'prev'} ) {
        $args{'prev'} = $self->step_before( $args{'for'} );
    }

    unless ( not defined $args{'prev'} ) {
        hyperlink(
            url => $args{'prev'},
            class => 'prev-button',
            label => $args{'prev_label'},
            as_button => 1,
        );
    }
};

private template 'next_step_button' => sub {
    my $self = shift;
    my %args = @_;

    if ( defined $args{'for'} and not defined $args{'next'} ) {
        $args{'next'} = $self->step_after( $args{'for'} );
    }

    unless ( defined $args{'next_label'} ) {
        # If there's no step before us
        if (     not defined $args{'prev'} and defined $args{'for'}
             and not defined $self->step_before($args{'for'}) ) {
            $args{'next_label'} = 'Start';
        }
        # The next step is the last one
        elsif (     defined $args{'next'}
                and not defined $self->step_after($args{'next'}) ) {
            $args{'next_label'} = 'Finish';
        }
        # Keep calm and carry on
        else {
            $args{'next_label'} = 'Next step';
        }
    }

    unless ( not defined $args{'next'} ) {
        if ( $args{'restart'} ) {
            Jifty->log->debug("Restarting the server before next setup wizard step");
            my $restart = new_action(
                class     => 'Jifty::Plugin::Config::Action::Restart',
                moniker   => 'restart-jifty',
                order     => 90
            );
            render_param(
                $restart      => 'url',
                default_value => $self->fragment_for($args{'next'})
            );
            form_submit(
                label => $args{'next_label'},
                class => 'next-button',
            );
        }
        else {
            form_submit(
                url     => $self->fragment_for($args{'next'}),
                label   => $args{'next_label'},
                class   => 'next-button',
            );
        }
    }
};

=head1 METHODS

=head2 config_field

A helper function for constructing a mini-form for a C<etc/config.yml> config field. It returns
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

=head2 steps

If you plan to use the L<button> template or L<step_before> and L<step_after>
methods, you must override this method to return a list of steps for your
setup wizard.

The steps are expected to be template paths to display in the order given.
They need not be absolute paths.

By default, it warns about misuse and returns an empty list.

=cut

sub steps {
    warn "You need to override the steps method in "
         .__PACKAGE__." to provide your own steps.";
    return qw();
}

=head2 step_before STEP

Returns the name of the step that came before the given STEP, or undef if
there is none (i.e. the first step).

=cut

sub step_before {
    my $self = shift;
    return $self->_step_for(shift, 'before');
}

=head2 step_after STEP

Returns the name of the step to come after the given STEP, or undef if there
is none (i.e. the last step).

=cut

sub step_after {
    my $self = shift;
    return $self->_step_for(shift, 'after');
}

=head2 _step_for STEP, DIRECTION

This is the logic behind L<step_before> and L<step_after>.  Returns the name
of the adjacent step in the DIRECTION given, or undef if there is none.

=cut

sub _step_for {
    my ($self, $step, $dir) = (@_);
    my @steps = $self->steps;

    my $new;
    for (0..$#steps) {
        if ( $step eq $steps[$_] ) {
            $new = $_;
            last;
        }
    }

    if ( $dir eq 'before' ) {
        $new--;
        undef $new if $new < 0;
    }
    elsif ( $dir eq 'after' ) {
        $new++;
        undef $new if $new > $#steps;
    }
    else {
        # Huh?
        undef $new;
    }

    return defined $new ? $steps[$new] : undef;
}


1;

