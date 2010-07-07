use warnings;
use strict;

package Jifty::Schema;
use Any::Moose;
extends 'Jifty::Object';

use SQL::ReservedWords;

=head1 NAME

Jifty::Schema - Jifty schemas

=cut

Jifty::Module::Pluggable->import(
    require     => 1,
    search_path => ["SQL::ReservedWords"],
    sub_name    => '_sql_dialects',
);

our %_SQL_RESERVED          = ();
our @_SQL_RESERVED_OVERRIDE = qw(value);
foreach my $dialect ( 'SQL::ReservedWords', &_sql_dialects ) {
    foreach my $word ( $dialect->words ) {
        push @{ $_SQL_RESERVED{ lc($word) } }, $dialect->reserved_by($word);
    }
}

# XXX TODO: QUESTIONABLE ENGINEERING DECISION
# The SQL standard forbids columns named 'value', but just about everone on the planet
# actually supports it. Rather than going about scaremongering, we choose
# not to warn people about columns named 'value'

delete $_SQL_RESERVED{ lc($_) } for (@_SQL_RESERVED_OVERRIDE);

=head1 ATTRIBUTES

=head2 flags

Takes and returns a hashref which holds schema management flags.  You
shouldn't need to set these yourself unless you're doing something funky with
the database.

=cut

has 'flags' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} }
);

=head1 METHODS

=head2 new

Returns a new Jifty::Schema. Takes no arguments. Will automatically figure out and initialize the models defined in the app's source.

=cut

sub BUILD {
    my $self = shift;
    $self->_init_model_list();
}

=head2 flags

=cut

=head2 _init_model_list

Reads in our application class from the config file and finds all our app's models.

=cut

sub _init_model_list {
    my $self = shift;

    # Plugins can have models too
    my @plugins = map { (ref $_).'::Model' } Jifty->plugins;

    # This creates a sub "models" which when called, finds packages under
    # the application's ::Model, requires them, and returns a list of their
    # names.
    Jifty::Module::Pluggable->import(
        require     => 1,
        except      => qr/\.#/,
        search_path => [ "Jifty::Model", Jifty->app_class("Model"), @plugins ],
        sub_name    => 'models',
    );
}

=head2 serialize_current_schema

Returns a serialization of the models in the app

=cut

sub serialize_current_schema {
    my $self = shift;    
   
    my @models = $self->model_classes;
    my $serialized_models = {};
    foreach my $model (@models) {
        $serialized_models->{$model->_class_name} = $model->serialize_metadata;
    }

    return $serialized_models;

}

sub setup_database {
    my $self = shift;

    $self->probe_database_existence();
    $self->manage_database_existence();

    if ( $self->flags->{'create_all_tables'} ) {
        $self->create_all_tables();
    } elsif ( $self->flags->{'setup_tables'} ) {
        $self->run_upgrades();
    }
}

=head2 probe_database_existence [NO_HANDLE]

Probes our database to see if it exists and is up to date.  This sets various
L</flags> for later use.

If AutoUpgrade is true in the application's config, this may cause the
database to be automatically upgraded.

Optionally takes a boolean to indicate whether or not we should bother to try
to create an actual database handle.

=cut

sub probe_database_existence {
    my $self      = shift;
    my $no_handle = 0;

    if ( $self->flags->{'create_database'} or $self->flags->{'drop_database'} ) {
        $no_handle = 1;
    }

    # Now try to connect.  We trap expected errors and deal with them.
    eval {
        Jifty->setup_database_connection(
            no_handle        => $no_handle,
            logger_component => 'SchemaTool',
        );
    };
    my $error = $@;

    if ( $error =~ /doesn't match (application schema|running jifty|running plugin) version/i 
         or $error =~ /plugin isn't installed in database/i ) {

        # We found an out-of-date DB.  Upgrade it
        $self->flags->{setup_tables} = 1;
    } elsif ( $error =~ /no version in the database/i ) {

        # No version table.  Assume the DB is empty.
        $self->flags->{create_all_tables} = 1;
    } elsif ( $error =~ /(database .*? (?:does not|doesn't) exist|unknown database)/i) {

        # No database exists; we'll need to make one and fill it up
        $self->flags->{drop_database}     = 0;
        $self->flags->{create_database}   = 1;
        $self->flags->{create_all_tables} = 1;
    } elsif ($error) {

        # Some other unexpected error; rethrow it
        die $error;
    }

    # Setting up tables requires creating the DB if we just dropped it
    $self->flags->{create_database} = 1
        if $self->flags->{drop_database} and $self->flags->{setup_tables};

    # Setting up tables on a just-created DB is the same as setting them all up
    $self->flags->{create_all_tables} = 1
        if $self->flags->{create_database} and $self->flags->{setup_tables};

    # Give us some kind of handle if we don't have one by now
    Jifty->handle( Jifty::Handle->new() ) unless Jifty->handle;
}

=head2 manage_database_existence

If the user wants the database created or it doesn't exist, creates the
database. If the user wants the old database deleted, does that too.

Dies with an error message if the database drop or create fails.

=cut

sub manage_database_existence {
    my $self = shift;

    my $handle = $self->connect_to_db_for_management();

    if ( $self->flags->{'print'} ) {
        $handle->drop_database('print')   if ( $self->flags->{'drop_database'} );
        $handle->create_database('print') if ( $self->flags->{'create_database'} );
    } else {
        if ( $self->flags->{'drop_database'} ) {
            my $ret = $handle->drop_database('execute');
            die "Error dropping database: ". $ret->error_message
                unless $ret or $ret->error_message =~ /database .*?(?:does not|doesn't) exist|unknown database/i;
        }

        if ( $self->flags->{'create_database'} ) {
            my $ret = $handle->create_database('execute');
            die "Error creating database: ". $ret->error_message unless $ret;
        }

        $handle->disconnect;
        $self->_reinit_handle() if ( $self->flags->{'create_database'} );
    }
}

sub _reinit_handle {
    Jifty->handle( Jifty::Handle->new() );
    Jifty->handle->connect();
}

=head2 create_all_tables

Create all tables for this application's models. Generally, this
happens on installation or running C<jifty schema>.

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
            $self->models );

    # Update the versions in the database
    Jifty::Model::Metadata->store( application_db_version => $appv );
    Jifty::Model::Metadata->store( jifty_db_version       => $jiftyv );

    # For each plugin, update the plugin version
    for my $plugin ( Jifty->plugins ) {
        my $pluginv = version->new( $plugin->version );
        Jifty::Model::Metadata->store(
            ( ref $plugin ) . '_db_version' => $pluginv );
    }

    unless ( $self->flags->{'no_bootstrap'} ) {

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
    my $sql    = '';

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

        $self->_check_reserved($model)
            unless ( $self->flags->{'ignore_reserved'}
            or !Jifty->config->framework('Database')->{'CheckSchema'} );

        if ( $self->flags->{'print'} ) {
            print $model->printable_table_schema;
        } else {
            $model->create_table_in_db;
        }
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
    if ( $self->flags->{'print'} ) {
        warn "Need to upgrade jifty_db_version to $appv here!";
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
    if ( $self->flags->{'print'} ) {
        warn "Need to upgrade application_db_version to $appv here!";
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
            if ( $self->flags->{'print'} ) {
                warn
                    "Need to upgrade ${plugin_class}_db_version to $appv here!";
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
                    } $self->models
            );

            # Save the plugin version to the database
            Jifty::Model::Metadata->store(
                $plugin_class . '_db_version' => $appv )
                unless $self->flags->{'print'};

            # Run the bootstrapper for initial data
            unless ( $self->flags->{'print'} ) {
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

    for my $model_class ( grep {/^\Q$baseclass\E::Model::/} $self->models ) {

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

            # Go through the currently-active columns
            for my $col ( grep { not $_->virtual and not $_->computed } $model->columns ) {

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

    if ( $self->flags->{'print'} ) {
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
                $self->_exec_sql($thing);
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

sub _exec_sql {
    my $self = shift;
    my $sql  = shift;
    my $ret  = Jifty->handle->simple_query($sql);
    die "error updating a table: " . $ret->error_message unless $ret;
}

sub _check_reserved {
    my $self  = shift;
    my $model = shift;
    my $log   = Log::Log4perl->get_logger("SchemaTool");
    foreach my $col ( $model->columns ) {
        if ( exists $_SQL_RESERVED{ lc( $col->name ) } ) {
            $log->error(
                      $model . ": "
                    . $col->name
                    . " is a reserved word in these SQL dialects: "
                    . join( ', ',
                    _classify_reserved_words( @{ $_SQL_RESERVED{ lc( $col->name ) } } ) )
            );
        }
    }
}

sub _classify_reserved_words {
    my %dbs;

    # Guess names of databases + their versions by breaking on last space,
    # e.g., "SQL Server 7" is ("SQL Server", "7"), not ("SQL", "Server 7").
    push @{ $dbs{ $_->[0] } }, $_->[1]
        for map { [ split /\s+(?!.*\s)/, $_, 2 ] } @_;
    return
        map { join " ", $_, __parenthesize_sql_variants( @{ $dbs{$_} } ) } sort keys %dbs;
}

sub __parenthesize_sql_variants {
    if ( not defined $_[0] ) { return () }
    if ( @_ == 1 )           { return $_[0] }
    return "(" . ( join ", ", @_ ) . ")";
}

=head2 connect_to_db_for_management

Returns a database handle suitable for direct manipulation.

=cut

sub connect_to_db_for_management {
    my $handle = Jifty::Handle->new();

    my $driver = Jifty->config->framework('Database')->{'Driver'};

    # Everything but the template1 database is assumed
    my %connect_args;
    $connect_args{'database'} = 'template1'
        if ( $handle->isa("Jifty::DBI::Handle::Pg") );
    $connect_args{'database'} = ''
        if ( $handle->isa("Jifty::DBI::Handle::mysql") );
    for ( 1 .. 50 ) {
        my $counter = $_;
        eval { $handle->connect(%connect_args); };
        my $err = $@;
        last if ( !$err || $err =~ /does not exist/i );
        sleep 1;
    }
    return $handle;
}

no Any::Moose;
__PACKAGE__->meta->make_immutable;
1;
