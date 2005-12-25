use warnings;
use strict;

package Jifty::Script::Schema;
use base qw/Jifty::Script::Command/;

use Pod::Usage;
use UNIVERSAL::require;
use YAML;
use version;
use Jifty::DBI::SchemaGenerator;

sub options {
    return 
      ("install|i" => "install",
       "print|p"   => "print",
       "create|c"  => "create",
       "force"     => "force",
       "include|I=s@" => "include",
       "help|?"    => "help",
       "man"       => "man");
}

sub run {
    my $self = shift;
    my $docs = \*DATA;

    # Option handling
    pod2usage( -exitval => 1, -input => $docs ) if  $self->{help};
    pod2usage( -exitval => 0, -verbose => 2, -input => $docs )
        if  $self->{man};

    pod2usage("$0: Must specify exactly one of --install or --print!")
        unless $self->{install} xor $self->{print};
    # Default to current directory
    push @ARGV, "." unless @ARGV;

    # Set up include path
    my $ProjectRoot = shift || ".";
    if ( $self->{include} ) {
        unshift @INC, @{ $self->{include} };
    }
    unshift @INC, "$ProjectRoot/lib";

    # Import Jifty
    Jifty->require                or die $UNIVERSAL::require::ERROR;
    Jifty::Model::Schema->require or die $UNIVERSAL::require::ERROR;

    # We trap the various "die" errors
   
    my $no_handle = 0;
    if ($self->{'create'} and $self->{'install'}) { 
        $no_handle = 1;
    }
    
    eval {
        Jifty->new(
            no_handle        => $no_handle,
            logger_component => 'SchemaTool',
        );
    };

    if ( $@ =~ /doesn't match application schema version/ ) {
        $self->{upgrade} = 1;
    }
    elsif ( $@ =~ /no version in the database/ ) {
        $self->{tables} = 1;
    }
    elsif ( $@ =~ /database .*? does not exist/ ) {
        $self->{tables} = 1;
        $self->{create} = 1;
    }
    elsif ($@) {
        die $@;
    }
    elsif ( $self->{create} and $self->{force}) {
        $self->{tables} = 1;

        # Don't fall through to exit
    }
    else {
        print "Database is installed and up to date; nothing to do\n";
        exit;
    }

    my $log = Log::Log4perl->get_logger("SchemaTool");
    $self->create_db() if $self->{create};

    # Set up application-specific parts
    my $ApplicationClass = Jifty->config->framework('ApplicationClass');
    my $SG               = Jifty::DBI::SchemaGenerator->new( Jifty->handle )
        or die "Can't make Jifty::DBI::SchemaGenerator";
    my $schema = Jifty::Model::Schema->new;

    # This creates a sub "models" which when called, finds packages under
    # $ApplicationClass::Model, requires them, and returns a list of their
    # names.
    require Module::Pluggable;
    Module::Pluggable->import(
        require     => 1,
        search_path => [ "Jifty::Model", $ApplicationClass . "::Model" ],
        sub_name    => 'models',
    );

    if ( $self->{tables} ) {
        $log->info("Generating SQL for application $ApplicationClass...");

        my $appv = version->new(
            Jifty->config->framework('Database')->{'Version'} );

        for my $model ( __PACKAGE__->models ) {

            # We don't want to get the Collections, or models that have a
            # 'since' that is after the current application version.

       # TODO XXX FIXME:
       #   This *will* try to generate SQL for abstract base classes you might
       #   stick in $AC::Model::.
            do { $log->info("Skipping $model"); next }
                if not UNIVERSAL::isa( $model, 'Jifty::Record' )
                or ( UNIVERSAL::can( $model, 'since' )
                and $appv < $model->since );

            $log->info("Using $model");
            my $ret = $SG->add_model( $model->new );
            $ret or die "couldn't add model $model: " . $ret->error_message;
        }

        if ( $self->{'print'} ) {
            print $SG->create_table_sql_text;
        }
        elsif ( $self->{'install'} ) {

            # Start a transactoin
            Jifty->handle->begin_transaction;

            # Run all CREATE commands
            for my $statement ( $SG->create_table_sql_statements ) {
                my $ret = Jifty->handle->simple_query($statement);
                $ret or die "error creating a table: " . $ret->error_message;
            }

            # Update the version in the database
            $schema->update($appv);

            # Load initial data
            eval {
                my $bootstrapper = $ApplicationClass . "::Bootstrap";
                $bootstrapper->require();

                $bootstrapper->run() if (UNIVERSAL::can($bootstrapper => 'run'));
            };
            die $@ if $@;

            # Commit it all
            Jifty->handle->commit;
        }

    }
    else {

        # Find current versions
        my $dbv  = $schema->in_db;
        my $appv = version->new(
            Jifty->config->framework('Database')->{'Version'} );
        if ( $appv < $dbv ) {
            print "Version $appv from module older than $dbv in database!\n";
            exit;
        }
        elsif ( $appv == $dbv ) {

            # Shouldn't happen
            print "Version $appv up to date.\n";
            exit;
        }
        $log->info(
            "Gerating SQL to update $ApplicationClass $dbv database to $appv"
        );

        my %UPGRADES;

        # Figure out what versions the upgrade knows about.
        eval {
            my $upgrader = $ApplicationClass . "::Upgrade";
            $upgrader->require();
            $UPGRADES{$_} = [ $upgrader->upgrade_to($_) ]
                for
                grep { $appv >= version->new($_) and $dbv < version->new($_) }
                $upgrader->versions();
        };

        for my $model ( __PACKAGE__->models ) {

            # We don't want to get the Collections, for example.
            do { warn "Skipping $model\n"; next }
                unless UNIVERSAL::isa( $model, 'Jifty::Record' );

            # Set us up the table
            $model = $model->new;
            my $t = $SG->_db_schema_table_from_model($model);

            # If this whole table is new
            if (    UNIVERSAL::can( $model, "since" )
                and $appv >= $model->since
                and $dbv < $model->since )
            {

                # Create it
                unshift @{ $UPGRADES{ $model->since } },
                    $t->sql_create_table( Jifty->handle->dbh );
            }
            else {

                # Go through the columns
                for my $column ( $model->columns ) {
                    next
                        if defined $column->refers_to
                        and defined $column->by;

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
            for ( map { @{ $UPGRADES{$_} } }
                sort { version->new($a) <=> version->new($b) }
                keys %UPGRADES )
            {
                if ( ref $_ ) {
                    print "-- Upgrade subroutine:\n";
                    require Data::Dumper;
                    $Data::Dumper::Pad     = "-- ";
                    $Data::Dumper::Deparse = 1;
                    $Data::Dumper::Indent  = 1;
                    $Data::Dumper::Terse   = 1;
                    print Data::Dumper::Dumper($_);
                }
                else {
                    print "$_;\n";
                }
            }
        }
        elsif ( $self->{'install'} ) {
            Jifty->handle->begin_transaction;
            for my $version ( sort { version->new($a) <=> version->new($b) }
                keys %UPGRADES )
            {
                $log->info("Upgrading through $version");
                for my $thing ( @{ $UPGRADES{$version} } ) {
                    if ( ref $thing ) {
                        $log->info("Running upgrade script");
                        $thing->();
                    }
                    else {
                        my $ret = Jifty->handle->simple_query($thing);
                        $ret
                            or die "error updating a table: "
                            . $ret->error_message;
                    }
                }
            }
            $schema->update($appv);
            $log->info("Upgraded to version $appv");
            Jifty->handle->commit;
        }
    }
}

sub create_db {
    my $self = shift;
    my $handle   = Jifty::Handle->new();
    my $database = lc Jifty->config->framework('Database')->{'Database'};
    my $driver = Jifty->config->framework('Database')->{'Driver'};

    if ( $self->{'print'} ) {
        print "DROP DATABASE $database;\n" if $self->{'force'};
        print "CREATE DATABASE $database;\n";
        return;
    }

    # Everything but the template1 database is assumed
    my %connect_args;
    $connect_args{'database'} = 'template1' if ($driver eq 'Pg');
    $handle->connect(%connect_args);
    warn "About to create the database";

    if ($driver eq 'SQLite') { 
        unlink($database);
    } else {
         $handle->simple_query("DROP DATABASE $database");

    }
    $handle->simple_query("CREATE DATABASE $database");

    $handle->disconnect;
    # reinit our handle
    Jifty->handle(Jifty::Handle->new());
    Jifty->handle->connect();
}

1;

__DATA__

=head1 NAME

schema - Create SQL to update or create your Jifty app's tables

=head1 SYNOPSIS

  jifty schema --install ProjectRoot  # Creates tables on SQL server 
  jifty schema --print   ProjectRoot  # Prints commands to update tables,
                                # now that they have been created

 Options:
   --print            Print output instead of running on SQL server
   --install          Run commands on server

   --create           Creates the database, if necessary
   --force            Drops the database before creating, in conjunction with B<--create>

   --include libpath  add libpath to C<@INC> (can be used multiple times)
   -I        libpath
   --help             brief help message
   --man              full documentation

=head1 OPTIONS

I<ProjectRoot> defaults to the current directory.  One of I<--install>
or I<--print> must be specified.

=over 8

=item B<--install>

Run the commands on the server

=item B<--print>

Prints the commands to standard output

=item B<--create>

Send CREATE DATABASE command

=item B<--force>

Send DROP DATABASE command, if used in conjunction with B<--create>

=item B<--include> I<libpath>, B<-I> I<libpath>

Prepends I<libpath> to Perl's C<@INC> array.  (You may want
this in order to locate your Jifty framework libraries.) You can
specify this as many times as you want:

  schema --print -I ../Jifty/lib -I ~/MyLibs ProjectRoot

Note that I<ProjectRoot>/lib is automatically added to C<@INC>.

=item B<--help>

Print a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

Looks in the directory I<ProjectRoot>/lib/ for all model classes and
generates SQL statements to create or update database tables for all
of the models.  It either prints the SQL to standard output
(B<--print>) or actually issues the C<CREATE TABLE> or C<ALTER TABLE>
statements on Jifty's database (B<--install>).  (Note that even if you
are just displaying the SQL, you need to have correctly configured
your Jifty database in I<ProjectRoot>C</etc/config.yml>, because the
SQL generated may depend on the database type.)

=head1 BUGS

Due to limitations of L<Jifty::DBI::SchemaGenerator>, this
probably only works with Postgres, and possibly recent mysql.

It is possible that some of this functionality should be rolled into
L<Jifty::DBI::SchemaGenerator>

=cut
