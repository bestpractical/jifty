use warnings;
use strict;

package Jifty::Script::Schema;
use base qw/Jifty::Script/;

use version;
use Jifty::DBI::SchemaGenerator;
use Jifty::Config;
use Jifty::Schema;

=head1 NAME

Jifty::Script::Schema - Create SQL to update or create your Jifty application's tables

=head1 SYNOPSIS

  jifty schema --setup      Creates or updates your application's database tables

 Options:
   --print            Print SQL, rather than executing commands

   --setup            Upgrade or install the database, creating it if need be
   --create-database  Only creates the database
   --drop-database    Drops the database
   --ignore-reserved-words   Ignore any SQL reserved words in schema definition
   --no-bootstrap     don't run bootstrap

   --help             brief help message
   --man              full documentation

=head1 DESCRIPTION

Manages your database.

=head2 options

=over 8

=item B<--print>

Rather than actually running the database create/update/drop commands,
Prints the commands to standard output

=item B<--create-database>

Send a CREATE DATABASE command.  Note that B<--setup>, below, will
automatically send a CREATE DATABASE if it needs one.  This option is
useful if you wish to create the database without creating any tables
in it.

=item B<--drop-database>

Send a DROP DATABASE command.  Use this in conjunction with B<--setup>
to wipe and re-install the database.

=item B<--setup>

Actually set up your app's tables.  This creates the database if need
be, and runs any commands needed to bring the tables up to date; these
may include CREATE TABLE or ALTER TABLE commands.  This option is
assumed if the database does not exist, or the database version is not
the same as the application's version.

=item B<--ignore-reserved-words>

Ignore any SQL reserved words used in table or column definitions, if
this option is not used and a reserved word is found it will cause an error.

=item B<--no-bootstrap>

don't run Bootstrap, mostly to get rid of creating initial data

=item B<--help>

Print a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=back

=cut

sub options {
    my $self = shift;
    return (
        $self->SUPER::options,
        "setup"                 => "setup_tables",
        "print|p"               => "print",
        "create-database|c"     => "create_database",
        "ignore-reserved-words" => "ignore_reserved",
        "drop-database"         => "drop_database",
        "no-bootstrap"          => "no_bootstrap",
    );
}

=head1 DESCRIPTION

Looks for all model classes of your Jifty application and generates
SQL statements to create or update database tables for all of the
models.  It either prints the SQL to standard output (B<--print>) or
actually issues the C<CREATE TABLE> or C<ALTER TABLE> statements on
Jifty's database.

(Note that even if you are just displaying the SQL, you need to have
correctly configured your Jifty database in
I<ProjectRoot>C</etc/config.yml>, because the SQL generated may depend
on the database type.)

By default checks for SQL reserved words in your table names and
column definitions, throwing an error if any are found.  

If you want to permanently turn this behaviour off you can set
CheckSchema to 0 in the database section of your applications config
file.

=head1 BUGS

Due to limitations of L<DBIx::DBSchema>, this probably only works with
PostgreSQL, MySQL and SQLite.

It is possible that some of this functionality should be rolled into
L<Jifty::DBI::SchemaGenerator>

=cut

=head1 METHODS

=head2 run

Prints a help message if the users want it. If not, goes about its
business.

Sets up the environment, checks current database state, creates or deletes
a database as necessary and then creates or updates your models' schema.

=cut

sub run {
    my $self = shift;

    $self->print_help();
    $self->setup_environment();
    $self->probe_database_existence();
    $self->manage_database_existence();
    if ( $self->{create_all_tables} ) {
        $self->create_all_tables();
    } elsif ( $self->{'setup_tables'} ) {
        $self->run_upgrades();
    } else {
        print "Done.\n";
    }
}

=head2 run_upgrades

Take the actions we need in order to bring an existing database up to current.

=cut

sub run_upgrades {
    my $self = shift;
    $self->upgrade_jifty_tables();
    $self->upgrade_plugin_tables();
    $self->upgrade_application_tables();
}

=head2 setup_environment

Sets up a minimal Jifty environment.

=cut

sub setup_environment {
    my $self = shift;

    # Import Jifty
    Jifty::Util->require("Jifty");
    Jifty::Util->require("Jifty::Model::Metadata");
    Jifty->new( no_handle => 1, logger_component => 'SchemaTool', )
        unless Jifty->class_loader;
}

=head2 schema

Returns a Jifty::Schema object.

=cut

sub schema {
    my $self = shift;

    $self->{'SCHEMA'} ||= Jifty::Schema->new();
    return $self->{'SCHEMA'};
}

=head2 probe_database_existence

Probes our database to see if it exists and is up to date.

=cut

sub probe_database_existence {
    my $self      = shift;
    my $no_handle = 0;
    if ( $self->{'create_database'} or $self->{'drop_database'} ) {
        $no_handle = 1;
    }

    # Now try to connect.  We trap expected errors and deal with them.
    eval {
        Jifty->setup_database_connection(
            no_handle        => $no_handle,
            logger_component => 'SchemaTool',
            check_opts       => { pretend => $self->{'print'} ? 1 : 0 }
        );
    };
    my $error = $@;

    if ( $error =~ /doesn't match (application schema|running jifty|running plugin) version/i 
         or $error =~ /plugin isn't installed in database/i ) {

        # We found an out-of-date DB.  Upgrade it
        $self->{setup_tables} = 1;
    } elsif ( $error =~ /no version in the database/i ) {

        # No version table.  Assume the DB is empty.
        $self->{create_all_tables} = 1;
    } elsif ( $error =~ /(database .*? (?:does not|doesn't) exist|unknown database)/i) {

        # No database exists; we'll need to make one and fill it up
        $self->{drop_database}     = 0;
        $self->{create_database}   = 1;
        $self->{create_all_tables} = 1;
    } elsif ($error) {

        # Some other unexpected error; rethrow it
        die $error;
    }

    # Setting up tables requires creating the DB if we just dropped it
    $self->{create_database} = 1
        if $self->{drop_database} and $self->{setup_tables};

   # Setting up tables on a just-created DB is the same as setting them all up
    $self->{create_all_tables} = 1
        if $self->{create_database} and $self->{setup_tables};

    # Give us some kind of handle if we don't have one by now
    Jifty->handle( Jifty::Handle->new() ) unless Jifty->handle;
}

=head2 create_all_tables

Create all tables for this application's models. Generally, this
happens on installation.

=cut

sub create_all_tables {
    my $self = shift;

    my $log = Log::Log4perl->get_logger("SchemaTool");
    $log->info("Generating SQL for application @{[Jifty->app_class]}...");

    my $appv
        = version->new( Jifty->config->framework('Database')->{'Version'} );
    my $jiftyv = version->new($Jifty::VERSION);

    # Start a transaction
    Jifty->handle->begin_transaction;

    $self->create_tables_for_models( grep { $_->isa('Jifty::DBI::Record') }
            $self->schema->models );

    # Update the versions in the database
    Jifty::Model::Metadata->store( application_db_version => $appv );
    Jifty::Model::Metadata->store( jifty_db_version       => $jiftyv );

    # For each plugin, update the plugin version
    for my $plugin ( Jifty->plugins ) {
        my $pluginv = version->new( $plugin->version );
        Jifty::Model::Metadata->store(
            ( ref $plugin ) . '_db_version' => $pluginv );
    }

    unless ( $self->{'no_bootstrap'} ) {

        # Load initial data
        eval {
            my $bootstrapper = Jifty->app_class("Bootstrap");
            Jifty::Util->require($bootstrapper);
            $bootstrapper->run() if $bootstrapper->can('run');

            for my $plugin ( Jifty->plugins ) {
                my $plugin_bootstrapper = $plugin->bootstrapper;
                Jifty::Util->require($plugin_bootstrapper);
                $plugin_bootstrapper->run() if $plugin_bootstrapper->can('run');
            }
        };
        die $@ if $@;
    }

    # Commit it all
    Jifty->handle->commit or exit 1;

    Jifty::Util->require('IPC::PubSub');
    IPC::PubSub->new(
        JiftyDBI => (
            db_config    => Jifty->handle->{db_config},
            table_prefix => '_jifty_pubsub_',
            db_init      => 1,
        )
    )->disconnect;
    $log->info("Set up version $appv, jifty version $jiftyv");
}

=head2 create_tables_for_models TABLEs

Given a list of items that are the scalar names of subclasses of Jifty::Record, 
either prints SQL or creates all those models in your database.

=cut

sub create_tables_for_models {
    my $self   = shift;
    my @models = (@_);

    my $log = Log::Log4perl->get_logger("SchemaTool");
    my $appv
        = version->new( Jifty->config->framework('Database')->{'Version'} );
    my $jiftyv = version->new($Jifty::VERSION);

    my %pluginvs;
    for my $plugin ( Jifty->plugins ) {
        my $plugin_class = ref $plugin;
        $pluginvs{$plugin_class} = version->new( $plugin->version );
    }

MODEL:
    for my $model (@models) {

   # Skip autogenerated models; that is, those that are overridden by plugins.
        next MODEL if Jifty::ClassLoader->autogenerated($model);
        my $plugin_root = Jifty->app_class('Plugin') . '::';

       # TODO XXX FIXME:
       #   This *will* try to generate SQL for abstract base classes you might
       #   stick in $AC::Model::.
        if ( $model->can('since') ) {
            my $app_class = Jifty->app_class;

            my $installed_version = 0;

            # Is it a Jifty core model?
            if ( $model =~ /^Jifty::Model::/ ) {
                $installed_version = $jiftyv;
            }

            # Is it a Jifty or application plugin model?
            elsif ( $model =~ /^(?:Jifty::Plugin::|$plugin_root)/ ) {
                my $plugin_class = $model;
                $plugin_class =~ s/::Model::(.*)$//;

                $installed_version = $pluginvs{$plugin_class};
            }

            # Otherwise, an application model
            else {
                $installed_version = $appv;
            }

            if ( $installed_version < $model->since ) {

                # XXX Is this message correct?
                $log->info(
                    "Skipping $model, as it should already be in the database"
                );
                next MODEL;
            }
        }

        if (    $model =~ /^(?:Jifty::Plugin::|$plugin_root)/
            and $model =~ /::Model::(.*)$/ )
        {
            my $model_name = $1;

            # Check to make sure this model is not overridden in the app,
            # in such cases we don't want to try to create the same table
            # twice, so let the app model do it rather than the plugin
            my $app_model = Jifty->app_class( "Model", $model_name );
            $app_model->require;
            next MODEL unless Jifty::ClassLoader->autogenerated($app_model);
        }

        $log->info("Using $model, as it appears to be new.");

        $self->schema->_check_reserved($model)
            unless ( $self->{'ignore_reserved'}
            or !Jifty->config->framework('Database')->{'CheckSchema'} );

        if ( $self->{'print'} ) {
            print $model->printable_table_schema;
        } else {
            $model->create_table_in_db;
        }
    }
}

=head2 upgrade_jifty_tables

Upgrade Jifty's internal tables.

=cut

sub upgrade_jifty_tables {
    my $self = shift;
    my $dbv  = Jifty::Model::Metadata->load('jifty_db_version');
    unless ($dbv) {

        # Backwards combatibility -- it usd to be 'key' not 'data_key';
        eval {
            local $SIG{__WARN__} = sub { };
            $dbv
                = Jifty->handle->fetch_result(
                "SELECT value FROM _jifty_metadata WHERE key = 'jifty_db_version'"
                );
        };
    }

    $dbv = version->new( $dbv || '0.60426' );
    my $appv = version->new($Jifty::VERSION);

    return
        unless $self->upgrade_tables(
        "Jifty" => $dbv,
        $appv, "Jifty::Upgrade::Internal"
        );
    if ( $self->{print} ) {
        warn "Need to upgrade jifty_db_version to $appv here!\n";
    } else {
        Jifty::Model::Metadata->store( jifty_db_version => $appv );
    }
}

=head2 upgrade_application_tables

Upgrade the application's tables.

=cut

sub upgrade_application_tables {
    my $self = shift;
    my $dbv  = version->new(
        Jifty::Model::Metadata->load('application_db_version') );
    my $appv
        = version->new( Jifty->config->framework('Database')->{'Version'} );

    return unless $self->upgrade_tables( Jifty->app_class, $dbv, $appv );
    if ( $self->{print} ) {
        warn "Need to upgrade application_db_version to $appv here!\n";
    } else {
        Jifty::Model::Metadata->store( application_db_version => $appv );
    }
}

=head2 upgrade_plugin_tables

Upgrade the tables for each plugin.

=cut

sub upgrade_plugin_tables {
    my $self = shift;

    for my $plugin ( Jifty->plugins ) {
        my $plugin_class = ref $plugin;

        my $dbv
            = Jifty::Model::Metadata->load( $plugin_class . '_db_version' );
        my $appv = version->new( $plugin->version );

        # Upgrade this plugin from dbv -> appv
        if ( defined $dbv ) {
            $dbv = version->new($dbv);

            next
                unless $self->upgrade_tables( $plugin_class, $dbv, $appv,
                $plugin->upgrade_class );
            if ( $self->{print} ) {
                warn
                    "Need to upgrade ${plugin_class}_db_version to $appv here!\n";
            } else {
                Jifty::Model::Metadata->store(
                    $plugin_class . '_db_version' => $appv );
            }
        }

        # Install this plugin
        else {
            my $log = Log::Log4perl->get_logger("SchemaTool");
            $log->info("Generating SQL to set up $plugin_class...");
            Jifty->handle->begin_transaction;

            # Create the tables
            $self->create_tables_for_models(
                grep {
                    $_->isa('Jifty::DBI::Record')
                        and /^\Q$plugin_class\E::Model::/
                    } $self->schema->models
            );

            # Save the plugin version to the database
            Jifty::Model::Metadata->store(
                $plugin_class . '_db_version' => $appv )
                unless $self->{print};

            # Run the bootstrapper for initial data
            unless ( $self->{print} ) {
                eval {
                    my $bootstrapper = $plugin->bootstrapper;
                    Jifty::Util->require($bootstrapper);
                    $bootstrapper->run if $bootstrapper->can('run');
                };
                die $@ if $@;
            }

            # Save them records
            Jifty->handle->commit;
            $log->info("Set up $plugin_class version $appv");
        }
    }
}

=head2 upgrade_tables BASECLASS, FROM, TO, [UPGRADECLASS]

Given a C<BASECLASS> to upgrade, and two L<version> objects, C<FROM>
and C<TO>, performs the needed transforms to the database.
C<UPGRADECLASS>, if not specified, defaults to C<BASECLASS>::Upgrade

=cut

sub upgrade_tables {
    my $self = shift;
    my ( $baseclass, $dbv, $appv, $upgradeclass ) = @_;
    $upgradeclass ||= $baseclass . "::Upgrade";

    my $log = Log::Log4perl->get_logger("SchemaTool");

    # Find current versions

    if ( $appv < $dbv ) {
        print
            "$baseclass version $appv from module older than $dbv in database!\n";
        return;
    } elsif ( $appv == $dbv ) {

        # Shouldn't happen
        print "$baseclass database version $appv up to date.\n";
        return;
    }
    $log->info("Generating SQL to upgrade $baseclass $dbv database to $appv");

    # Figure out what versions the upgrade knows about.
    Jifty::Util->require($upgradeclass) or return;
    my %UPGRADES;
    eval {
        $UPGRADES{$_} = [ $upgradeclass->upgrade_to($_) ]
            for grep { $appv >= version->new($_) and $dbv < version->new($_) }
            $upgradeclass->versions();
    };

    for my $model_class ( grep {/^\Q$baseclass\E::Model::/}
        $self->schema->models )
    {

        # We don't want to get the Collections, for example.
        next unless $model_class->isa('Jifty::DBI::Record');

        # Set us up the table
        my $model = $model_class->new;

        # If this whole table is new Create it
        if (    $model->can('since')
            and defined $model->since
            and $appv >= $model->since
            and $model->since > $dbv )
        {
            unshift @{ $UPGRADES{ $model->since } },
                $model->table_schema_statements();
        } else {
            # Go through the columns
            for my $col ( grep { not $_->virtual and not $_->computed } $model->all_columns ) {

                # If they're old, drop them
                if ( defined $col->till and $appv >= $col->till and $col->till > $dbv ) {
                    push @{ $UPGRADES{ $col->till } }, sub {
                        my $renamed = $upgradeclass->just_renamed || {};

                        # skip it if this was dropped by a rename
                        $model->drop_column_in_db($col->name)
                            unless defined $renamed->{ $model->table }->{'drop'}->{ $col->name };
                    };
                }

                # If they're new, add them
                if (    $col->can('since')
                    and defined $col->since
                    and $appv >= $col->since
                    and $col->since > $dbv )
                {
                    unshift @{ $UPGRADES{ $col->since } }, sub {
                        my $renamed = $upgradeclass->just_renamed || {};

                        # skip it if this was added by a rename
                        $model->add_column_in_db( $col->name ) unless
                            defined $renamed->{ $model->table }->{'add'}
                            ->{ $col->name };
                    };
                }
            }
        }
    }

    if ( $self->{'print'} ) {
        $self->_print_upgrades(%UPGRADES);

    } else {
        eval {
            $self->_execute_upgrades(%UPGRADES);
            $log->info("Upgraded to version $appv");
        };
        die $@ if $@;
    }
    return 1;
}

sub _execute_upgrades {
    my $self     = shift;
    my %UPGRADES = (@_);
    Jifty->handle->begin_transaction;
    my $log = Log::Log4perl->get_logger("SchemaTool");
    for my $version ( sort { version->new($a) <=> version->new($b) }
        keys %UPGRADES )
    {
        $log->info("Upgrading through $version");
        for my $thing ( @{ $UPGRADES{$version} } ) {
            if ( ref $thing ) {
                $log->info("Running upgrade script");
                $thing->();
            } else {
                _exec_sql($thing);
            }
        }
    }
    Jifty->handle->commit;
}

sub _print_upgrades {
    my $self     = shift;
    my %UPGRADES = (@_);
    for (
        map  { @{ $UPGRADES{$_} } }
        sort { version->new($a) <=> version->new($b) }
        keys %UPGRADES
        )
    {
        if ( ref $_ ) {
            print "-- Upgrade subroutine:\n";
            require Data::Dumper;
            $Data::Dumper::Pad     = "-- ";
            $Data::Dumper::Deparse = 1;
            $Data::Dumper::Indent  = 1;
            $Data::Dumper::Terse   = 1;
            print Data::Dumper::Dumper($_);
        } else {
            print "$_;\n";
        }
    }
}

=head2 manage_database_existence

If the user wants the database created, creates the database. If the
user wants the old database deleted, does that too.  Exits with a
return value of 1 if the database drop or create fails.

=cut

sub manage_database_existence {
    my $self = shift;

    my $handle = Jifty::Schema->connect_to_db_for_management();

    if ( $self->{print} ) {
        $handle->drop_database('print')   if ( $self->{'drop_database'} );
        $handle->create_database('print') if ( $self->{'create_database'} );
    } else {
        if ( $self->{'drop_database'} ) {
            my $ret = $handle->drop_database('execute');
            die "Error dropping database: ". $ret->error_message
                unless $ret or $ret->error_message =~ /database .*?(?:does not|doesn't) exist|unknown database/i;
        }

        if ( $self->{'create_database'} ) {        
            my $ret = $handle->create_database('execute');
            die "Error creating database: ". $ret->error_message unless $ret;
        }

        $handle->disconnect;
        $self->_reinit_handle() if ( $self->{'create_database'} );
    }
}

sub _reinit_handle {
    Jifty->handle( Jifty::Handle->new() );
    Jifty->handle->connect();
}

sub _exec_sql {
    my $sql = shift;
    my $ret = Jifty->handle->simple_query($sql);
    die "error updating a table: " . $ret->error_message unless $ret;
}

1;
