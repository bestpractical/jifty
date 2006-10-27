use warnings;
use strict;

package Jifty::Script::Schema;
use base qw/App::CLI::Command/;

use Pod::Usage;
use version;
use Jifty::DBI::SchemaGenerator;
use Jifty::Config;
use SQL::ReservedWords;

Jifty::Module::Pluggable->import(
    require     => 1,
    search_path => [ "SQL::ReservedWords"],
    sub_name => '_sql_dialects',
);  
        
            

our %_SQL_RESERVED = ();
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

delete $_SQL_RESERVED{lc($_)} for (@_SQL_RESERVED_OVERRIDE);

=head2 options

Returns a hash of all the options this script takes. (See the usage message for details)

=cut


sub options {
    return (
        "setup"             => "setup_tables",
        "print|p"           => "print",
        "create-database|c" => "create_database",
        "ignore-reserved-words" => "ignore_reserved",
        "drop-database"     => "drop_database",
        "help|?"            => "help",
        "man"               => "man"
    );
}

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
    $self->prepare_model_classes();
    if ( $self->{create_all_tables} ) {
        $self->create_all_tables();
    } elsif ( $self->{'setup_tables'} ) {
        $self->upgrade_jifty_tables();
        $self->upgrade_application_tables();
    } else {
        print "Done.\n";
    }
}


=head2 setup_environment

Sets up a minimal Jifty environment.

=cut

sub setup_environment {
    my $self = shift;

    # Import Jifty
    Jifty::Util->require("Jifty");
    Jifty::Util->require("Jifty::Model::Metadata");
}


=head2 print_help

Prints out help for the package using pod2usage.

If the user specified --help, prints a brief usage message

If the user specified --man, prints out a manpage

=cut

sub print_help {
    my $self = shift;

    # Option handling
    my $docs = \*DATA;
    pod2usage( -exitval => 1, -input => $docs ) if $self->{help};
    pod2usage( -exitval => 0, -verbose => 2, -input => $docs )
        if $self->{man};
}


=head2 prepare_model_classes

Reads in our application class from the config file, sets up a schema
generator and finds all our app's models.

=cut

sub prepare_model_classes {

    my $self = shift;

    # Set up application-specific parts
    $self->{'_application_class'}
        = Jifty->config->framework('ApplicationClass');
    $self->{'_schema_generator'}
        = Jifty::DBI::SchemaGenerator->new( Jifty->handle )
        or die "Can't make Jifty::DBI::SchemaGenerator";

# This creates a sub "models" which when called, finds packages under
# $self->{'_application_class'}::Model, requires them, and returns a list of their
# names.
    Jifty::Module::Pluggable->import(
        require     => 1,
        except      => qr/\.#/,
        search_path =>
            [ "Jifty::Model", $self->{'_application_class'} . "::Model" ],
        sub_name => 'models',
    );
}


=head2 probe_database_existence

Probes our database to see if it exists and is up to date.

=cut

sub probe_database_existence {
    my $self = shift;

    my $no_handle = 0;
    if ( $self->{'create_database'} or $self->{'drop_database'}) {
        $no_handle = 1;
    }

    # Now try to connect.  We trap expected errors and deal with them.
    eval {
        Jifty->new(
            no_handle        => $no_handle,
            logger_component => 'SchemaTool',
        );
    };
    
    if ( $@ =~ /doesn't match (application schema|running jifty) version/i) {
        # We found an out-of-date DB.  Upgrade it
        $self->{setup_tables} = 1;
    } elsif ( $@ =~ /no version in the database/i ) {
        # No version table.  Assume the DB is empty.
        $self->{create_all_tables} = 1;
    } elsif ( $@ =~ /database .*? does not exist/i or $@ =~ /unknown database/) {
        # No database exists; we'll need to make one and fill it up
        $self->{create_database}   = 1;
        $self->{create_all_tables} = 1;
    } elsif ($@) {
        # Some other unexpected error; rethrow it
        die $@;
    }

    # Setting up tables requires creating the DB if we just dropped it
    $self->{create_database} = 1   if $self->{drop_database} and $self->{setup_tables};

    # Setting up tables on a just-created DB is the same as setting them all up
    $self->{create_all_tables} = 1 if $self->{create_database} and $self->{setup_tables};

    # Give us some kind of handle if we don't have one by now
    Jifty->handle( Jifty::Handle->new() ) unless Jifty->handle;
}


=head2 create_all_tables

Create all tables for this application's models. Generally, this
happens on installation.

=cut

sub create_all_tables {
    my $self = shift;

    my $log    = Log::Log4perl->get_logger("SchemaTool");
    $log->info(
        "Generating SQL for application $self->{'_application_class'}...");

    my $appv
        = version->new( Jifty->config->framework('Database')->{'Version'} );
    my $jiftyv
        = version->new( $Jifty::VERSION || '0.60426' );

    for my $model ( __PACKAGE__->models ) {

        # We don't want to get the Collections, or models that have a
        # 'since' that is after the current application version.

       # TODO XXX FIXME:
       #   This *will* try to generate SQL for abstract base classes you might
       #   stick in $AC::Model::.
        next unless $model->isa( 'Jifty::Record' );
        do { $log->info("Skipping $model"); next }
            if ( $model->can( 'since' )
            and ($model =~ /^Jifty::Model::/ ? $jiftyv : $appv) < $model->since );

        $log->info("Using $model");
        my $ret = $self->{'_schema_generator'}->add_model( $model->new );
        $ret or die "couldn't add model $model: " . $ret->error_message;
        unless ($self->{'ignore_reserved'} or
         !Jifty->config->framework('Database')->{'CheckSchema'} ) {
                $self->_check_reserved($model);
        }


    }
     


    if ( $self->{'print'} ) {
        print $self->{'_schema_generator'}->create_table_sql_text;
    } else {
        # Start a transaction
        Jifty->handle->begin_transaction;

        # Run all CREATE commands
        for my $statement (
            $self->{'_schema_generator'}->create_table_sql_statements )
        {
            my $ret = Jifty->handle->simple_query($statement);
            $ret or die "error creating a table: " . $ret->error_message;
        }

        # Update the versions in the database
        Jifty::Model::Metadata->store( application_db_version => $appv);
        Jifty::Model::Metadata->store( jifty_db_version => $jiftyv);

        # Load initial data
        eval {
            my $bootstrapper = $self->{'_application_class'} . "::Bootstrap";
            Jifty::Util->require($bootstrapper);

            $bootstrapper->run()
                if  $bootstrapper->can( 'run' );
        };
        die $@ if $@;

        # Commit it all
        Jifty->handle->commit;
    }

    Jifty::Util->require('IPC::PubSub');
    IPC::PubSub->new(
        JiftyDBI => (
            db_config    => Jifty->handle->{db_config},
            table_prefix => '_jifty_pubsub_',
            db_init      => 1,
        )
    );
    $log->info("Set up version $appv, jifty version $jiftyv");
}


=head2 upgrade_jifty_tables

Upgrade Jifty's internal tables.

=cut

sub upgrade_jifty_tables {
    my $self = shift;
    my $dbv  = Jifty::Model::Metadata->load( 'jifty_db_version' );
    unless ($dbv) {
        # Backwards combatibility -- it usd to be 'key' not 'data_key';
        eval {
            local $SIG{__WARN__} = sub { };
            $dbv = Jifty->handle->fetch_result(
                "SELECT value FROM _jifty_metadata WHERE key = 'jifty_db_version'");
        };
    }
    $dbv ||= '0.60426';
    $dbv = version->new($dbv);

    my $appv = version->new( $Jifty::VERSION );

    return unless $self->upgrade_tables( "Jifty" => $dbv, $appv, "Jifty::Upgrade::Internal" );
    if( $self->{print} ) {
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
    my $dbv = version->new( Jifty::Model::Metadata->load( 'application_db_version' ) );
    my $appv
        = version->new( Jifty->config->framework('Database')->{'Version'} );

    return unless $self->upgrade_tables( $self->{_application_class} => $dbv, $appv );
    if( $self->{print} ) {
        warn "Need to upgrade application_db_version to $appv here!";
    } else {
        Jifty::Model::Metadata->store( application_db_version => $appv );
    }
}

=head2 upgrade_tables BASECLASS, FROM, TO, [UPGRADECLASS]

Given a C<BASECLASS> to upgrade, and two L<version> objects, C<FROM>
and C<TO>, performs the needed transforms to the database.
C<UPGRADECLASS>, if not specified, defaults to C<BASECLASS>::Upgrade

=cut

sub upgrade_tables {
    my $self = shift;
    my ($baseclass, $dbv, $appv, $upgradeclass ) = @_;
    $upgradeclass ||= $baseclass."::Upgrade";

    my $log    = Log::Log4perl->get_logger("SchemaTool");
    # Find current versions

    if ( $appv < $dbv ) {
        print "$baseclass version $appv from module older than $dbv in database!\n";
        return;
    } elsif ( $appv == $dbv ) {
        # Shouldn't happen
        print "$baseclass version $appv up to date.\n";
        return;
    }
    $log->info(
        "Generating SQL to upgrade $baseclass $dbv database to $appv"
    );

    # Figure out what versions the upgrade knows about.
    Jifty::Util->require($upgradeclass) or return;
    my %UPGRADES;
    eval {
        $UPGRADES{$_} = [ $upgradeclass->upgrade_to($_) ]
            for grep { $appv >= version->new($_) and $dbv < version->new($_) }
            $upgradeclass->versions();
    };

    for my $model ( grep {/^\Q$baseclass\E::Model::/} __PACKAGE__->models ) {

        # We don't want to get the Collections, for example.
        do {next} unless $model->isa( 'Jifty::Record' );

        # Set us up the table
        $model = $model->new;
        my $t = $self->{'_schema_generator'}
            ->_db_schema_table_from_model($model);

        # If this whole table is new
        if (    $model->can( 'since' )
            and $appv >= $model->since
            and $dbv < $model->since )
        {

            # Create it
            unshift @{ $UPGRADES{ $model->since } },
                $t->sql_create_table( Jifty->handle->dbh );
        } else {

            # Go through the columns
            for my $column ( $model->columns ) {
                next if $column->virtual;

                # If they're old, drop them
                if (    defined $column->until
                    and $appv >= $column->until
                    and $dbv < $column->until )
                {
                    push @{ $UPGRADES{ $column->until } },
                        "ALTER TABLE "
                        . $model->table
                        . " DROP COLUMN "
                        . $column->name;
                }

                # If they're new, add them
                if (    defined $column->since
                    and $appv >= $column->since
                    and $dbv < $column->since )
                {
                    unshift @{ $UPGRADES{ $column->since } },
                        "ALTER TABLE "
                        . $model->table
                        . " ADD COLUMN "
                        . $t->column( $column->name )
                        ->line( Jifty->handle->dbh );
                }
            }
        }
    }

    if ( $self->{'print'} ) {
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
    } else {
        Jifty->handle->begin_transaction;
        for my $version (
            sort { version->new($a) <=> version->new($b) }
            keys %UPGRADES
            )
        {
            $log->info("Upgrading through $version");
            for my $thing ( @{ $UPGRADES{$version} } ) {
                if ( ref $thing ) {
                    $log->info("Running upgrade script");
                    $thing->();
                } else {
                    my $ret = Jifty->handle->simple_query($thing);
                    $ret
                        or die "error updating a table: "
                        . $ret->error_message;
                }
            }
        }
        $log->info("Upgraded to version $appv");
        Jifty->handle->commit;
    }
    return 1;
}


=head2 manage_database_existence

If the user wants the database created, creates the database. If the
user wants the old database deleted, does that too.

=cut

sub manage_database_existence {
    my $self     = shift;
    my $handle   = Jifty::Handle->new();
    my $database = Jifty::Handle->canonical_database_name;
    my $driver   = Jifty->config->framework('Database')->{'Driver'};

    # Everything but the template1 database is assumed
    my %connect_args;
    $connect_args{'database'} = 'template1' if ( $driver eq 'Pg' );
    $connect_args{'database'} = '' if ( $driver eq 'mysql' );
    $handle->connect(%connect_args);

    if ( $self->{'drop_database'} ) {
        if ( $self->{'print'} ) {
            print "DROP DATABASE $database;\n";
        } elsif ( $driver eq 'SQLite' ) {
            # Win32 complains when you try to unlink open DB
            $handle->disconnect if $^O eq 'MSWin32';
            unlink($database);
        } else {
            $handle->simple_query("DROP DATABASE $database");
        }
    }

    if ( $self->{'create_database'} ) {
        if ( $self->{'print'} ) {
            print "CREATE DATABASE $database;\n";
        } elsif ( $driver ne 'SQLite' ) {
            $handle->simple_query("CREATE DATABASE $database");
        }
    }

    $handle->disconnect;

    # If we drop and didn't re-create, then don't reconnect
    return if $self->{'drop_database'} and not $self->{'create_database'};

    # Likewise if we didn't get a connection before, and we're just
    # printing, the connect below will fail
    return if $self->{'print'} and not ( Jifty->handle and Jifty->handle->dbh->ping );

    # Otherwise, reinit our handle
    Jifty->handle( Jifty::Handle->new() );
    Jifty->handle->connect();
}

sub __parenthesize {
    if (not defined $_[0]) { return () }
    if (@_ == 1)           { return $_[0] }
    return "(" . (join ", ", @_) . ")";
}

sub _classify {
    my %dbs;
    # Guess names of databases + their versions by breaking on last space,
    # e.g., "SQL Server 7" is ("SQL Server", "7"), not ("SQL", "Server 7").
    push @{ $dbs{$_->[0]} }, $_->[1] for map { [ split /\s+(?!.*\s)/, $_, 2 ] } @_;
    return map { join " ", $_, __parenthesize(@{ $dbs{$_} }) } sort keys %dbs;
}

sub _check_reserved {
    my $self  = shift;
    my $model = shift;
    my $log   = Log::Log4perl->get_logger("SchemaTool");
    foreach my $col ( $model->columns ) {
        if ( exists $_SQL_RESERVED{ lc( $col->name ) } ) {
            $log->error( $model . ": "
                    . $col->name
                    . " is a reserved word in these SQL dialects: "
                    . join( ', ', _classify(@{ $_SQL_RESERVED{ lc( $col->name ) } }) ) );
        }
    }
}

1;

__DATA__

=head1 NAME

Jifty::Script::Schema - Create SQL to update or create your Jifty app's tables

=head1 SYNOPSIS

  jifty schema --setup      Creates or updates your application's database tables

 Options:
   --print            Print SQL, rather than executing commands

   --setup            Upgrade or install the database, creating it if need be
   --create-database  Only creates the database
   --drop-database    Drops the database

   --help             brief help message
   --man              full documentation

=head1 OPTIONS

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

=item B<--help>

Print a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=back

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

=head1 BUGS

Due to limitations of L<DBIx::DBSchema>, this probably only works with
PostgreSQL, MySQL and SQLite.

It is possible that some of this functionality should be rolled into
L<Jifty::DBI::SchemaGenerator>

=cut
