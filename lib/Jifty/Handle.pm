use warnings;
use strict;

package Jifty::Handle;

=head1 NAME

Jifty::Handle -- A database handle class for Jifty

=head1 DESCRIPTION

A wrapper around Jifty::DBI::Handle which is aware of versions in the
database

=cut

use Jifty::Util;
our @ISA;

=head1 METHODS

=head2 new PARAMHASH

This class method instantiates a new L<Jifty::Handle> object. This
object deals with database handles for the system.  After it is
created, it will be a subclass of L<Jifty::DBI::Handle>.

=cut

# Setup database handle based on config data
sub new {
    my $class = shift;

    if (my $handle_class = Jifty->config->framework('Database')->{'HandleClass'}) {
        if ($handle_class ne $class) {
            Jifty::Util->require( $handle_class );
            return $handle_class->new(@_);
        }
    }

    my $driver = Jifty->config->framework('Database')->{'Driver'};
    if ( $driver eq 'Oracle' ) {
        $ENV{'NLS_LANG'}  = "AMERICAN_AMERICA.AL32UTF8";
        $ENV{'NLS_NCHAR'} = "AL32UTF8";
    }

    # We do this to avoid Jifty::DBI::Handle's magic reblessing, because
    # it breaks subclass methods.
    my $driver_class = "Jifty::DBI::Handle::" . $driver;
    Jifty::Util->require($driver_class);

    die "No such handle class as $driver_class. ",
        "Check your spelling and check that your Jifty installation and ",
        "related modules (especially Jifty::DBI) are up to date."
        unless $driver_class->can('isa');

    unshift @ISA, $driver_class;
    return $class->SUPER::new();
}

=head2 canonical_database_name

Returns the canonical name of the application's database (the actual name that will
be given to the database driver).  This name is a lower-case version of the C<Database>
argument in the C<Database> section of the framework config.

For SQLite databases (where the database name is actually a filename), this also converts
a relative path into an absolute path based at the application root.

=cut

sub canonical_database_name {
    my $self_or_class = shift;
    my $db_config     = Jifty->config->framework('Database');

    # XXX TODO consider canonicalizing to all-lowercase, once there are no
    # legacy databases
    my $db = $db_config->{'Database'};

    if ( $db_config->{'Driver'} =~ /SQLite/ ) {
        $db = Jifty::Util->absolute_path($db);
    }

    return $db;
}

=head2 connect ARGS

Like L<Jifty::DBI>'s connect method but pulls the name of the database
from the current L<Jifty::Config>.

=cut

sub connect {
    my $self      = shift;
    my %args      = (@_);
    my %db_config = (
        %{ Jifty->config->framework('Database') },
        Database => $self->canonical_database_name
    );

    my %lc_db_config;

    # Skip the non-dsn keys, but not anything else
    for (
        grep {
            !/^autoupgrade|checkschema|version|forwardcompatible|recordbaseclass|attributes$/i
        } keys %db_config
        )
    {
        $lc_db_config{ lc($_) } = $db_config{$_};
    }
    $self->SUPER::connect( %lc_db_config, %args );
    $self->{db_config} = { %lc_db_config, %args };
    $self->dbh->{LongReadLen} = Jifty->config->framework('MaxAttachmentSize')
        || '10000000';

    # setup attributes
    my $attributes = Jifty->config->framework('Database')->{Attributes} || {};
    for ( keys %$attributes ) {
        $self->dbh->{ lc($_) } = $attributes->{$_};
    }
}

=head2 check_schema_version

Make sure that we have a recent enough database schema.  If we don't,
then error out.

=cut

sub check_schema_version {
    my $self = shift;
    require Jifty::Model::Metadata;
    my $autoup = delete Jifty->config->framework('Database')->{'AutoUpgrade'};

    # Application db version check
    {
        my $dbv  = Jifty::Model::Metadata->load("application_db_version");
        my $appv = Jifty->config->framework('Database')->{'Version'};

        if ( not defined $dbv ) {

      # First layer of backwards compatibility -- it used to be in _db_version
            my @v;
            eval {
                local $SIG{__WARN__} = sub { };
                @v = Jifty->handle->fetch_result(
                    "SELECT major, minor, rev FROM _db_version");
            };
            $dbv = join( ".", @v ) if @v == 3;
        }
        if ( not defined $dbv ) {

            # It was also called the 'key' column, not the data_key column
            eval {
                local $SIG{__WARN__} = sub { };
                $dbv
                    = Jifty->handle->fetch_result(
                    "SELECT value FROM _jifty_metadata WHERE key = 'application_db_version'"
                    );
            } or undef($dbv);
        }

        die
            "Application schema has no version in the database; perhaps you need to run this:\n"
            . "\t bin/jifty schema --setup\n"
            unless defined $dbv;

        unless ( version->new($appv) == version->new($dbv) ) {

        # if app version is older than db version, but we are still compatible
            my $compat = delete Jifty->config->framework('Database')
                ->{'ForwardCompatible'} || $appv;
            if (   version->new($appv) > version->new($dbv)
                || version->new($compat) < version->new($dbv) )
            {
                warn
                    "Application schema version in database ($dbv) doesn't match application schema version ($appv)\n";
                if ( $autoup ) {
                    warn
                        "Automatically upgrading your database to match the current application schema";
                    $self->_upgrade_schema();
                } else {
                    die
                        "Please run `bin/jifty schema --setup` to upgrade the database.\n";
                }
            }
        }
    }

    # Jifty db version check
    {

        # If we got here, the application had a version (somehow) so
        # this is an upgrade.  If $dbv is undef, it's because it's
        # from before when the _jifty_metadata table existed.
        my $dbv
            = version->new( Jifty::Model::Metadata->load("jifty_db_version")
                || '0.60426' );
        my $appv = version->new($Jifty::VERSION);
        unless ( $appv == $dbv ) {
            warn
                "Internal jifty schema version in database ($dbv) doesn't match running jifty version ($appv)\n";
            if ($autoup) {
                warn
                    "Automatically upgrading your database to match the current Jifty schema\n";
                $self->_upgrade_schema;
            } else {
                die
                    "Please run `bin/jifty schema --setup` to upgrade the database.\n";
            }
        }
    }

    # Plugin version check
    for my $plugin ( Jifty->plugins ) {
        my $plugin_class = ref $plugin;

        my $dbv
            = Jifty::Model::Metadata->load( $plugin_class . '_db_version' );
        my $appv = version->new( $plugin->version );

        if ( not defined $dbv ) {
            warn
                "$plugin_class plugin isn't installed in database\n";
            if ($autoup) {
                warn
                    "Automatically upgrading your database to match the current plugin schema\n";
                $self->_upgrade_schema;
            } else {
                die
                    "Please run `bin/jifty schema --setup` to upgrade the database.\n";
            }
        } elsif (version->new($dbv) < $appv) {
            warn
                "$plugin_class plugin version in database ($dbv) doesn't match running plugin version ($appv)\n";
            if ($autoup) {
                warn
                    "Automatically upgrading your database to match the current plugin schema\n";
                $self->_upgrade_schema;
            } else {
                die
                    "Please run `bin/jifty schema --setup` to upgrade the database.\n";
            }
        }
    }

}

=head2 create_database MODE

C<MODE> is either "print" or "execute".

This method either prints the commands necessary to create the database
or actually creates it, depending on the value of MODE.

=cut

sub create_database {
    my $self     = shift;
    my $mode     = shift || 'execute';
    my $database = $self->canonical_database_name;
    my $driver   = Jifty->config->framework('Database')->{'Driver'};
    my $query    = "CREATE DATABASE $database";
    $query .= " TEMPLATE template0" if $driver =~ /Pg/;
    if ( $mode eq 'print' ) {
        print "$query;\n";
    } elsif ( $driver !~ /SQLite/ ) {
        $self->simple_query($query);
    }
}

=head2 drop_database MODE

C<MODE> is either "print" or "execute".

This method either prints the commands necessary to drop the database
or actually drops it, depending on the value of MODE.

=cut

sub drop_database {
    my $self     = shift;
    my $mode     = shift || 'execute';
    my $database = $self->canonical_database_name;
    my $driver   = Jifty->config->framework('Database')->{'Driver'};
    if ( $mode eq 'print' ) {
        print "DROP DATABASE $database;\n";
    } elsif ( $driver =~ /SQLite/ ) {

        # Win32 complains when you try to unlink open DB
        $self->disconnect if $^O eq 'MSWin32';
        unlink($database);
    } else {
        local $SIG{__WARN__}
            = sub { warn $_[0] unless $_[0] =~ /exist|couldn't execute/i };
        $self->simple_query("DROP DATABASE $database");
    }
}

=head2 delete

Delete UUIDs on successful delete.

=cut

sub delete {
    my $self = shift;
    my ($table, @pairs) = @_;

    # XXX TODO FIXME This is expensive, but since an ID might be reused
    # (especially on SQLite) and cause things to blow up, we have to do this.
    my @bind = ();
    my $where = 'WHERE ';
    while (my $key = shift @pairs) {
        $where .= $key . "=?" . " AND ";
        push( @bind, shift(@pairs) );
    }

    $where =~ s/AND $//;
    my $query_string = "SELECT id FROM " . $table . ' ' . $where;
    my $sth = $self->simple_query($query_string, @bind);

    my @delete_ids = ();
    while (my ($id) = $sth->fetchrow_array) {
        push @delete_ids, $id;
    }

    my $ret;
    if ($ret = $self->SUPER::delete(@_)) {
        for my $id (@delete_ids) {
            $self->SUPER::delete('_jifty_uuids',
                row_table => $table,
                row_id    => $id,
            );
        }
    }

    return $ret;
}

=head2 insert

Assign an UUID for each successfully inserted rows.

=cut

sub insert {
    my $self  = shift;
    my $table = shift;
    my %args = (@_);
    my $uuid  = delete($args{__uuid});

    my $rv = $self->SUPER::insert($table, %args);

    if ($rv and ($uuid || Jifty->config->framework('Database')->{'RecordUUIDs'} !~ /^(?:lazy|off)/i) ) {
        $self->_insert_uuid( table => $table, id => $rv, uuid => $uuid);

    }

    return $rv;
}


sub _insert_uuid {
    my $self = shift;
    my %args = (table => undef,
                id => undef,
                uuid => undef,
                @_);

    my $uuid =  ($args{uuid} || Jifty::Util->generate_uuid);

    # Generate a UUID on the sideband: $table - $rv - UUID.
    $self->dbh->do(
        qq[ INSERT INTO _jifty_uuids VALUES (?, ?, ?) ], {},
        $uuid , $args{table}, $args{id}
    );

    return $uuid; 
}

=head2 bootstrap_uuid_table 

Create the side-band table that gives each record its own UUID.

=cut

sub bootstrap_uuid_table {
    my $self = shift;

    $self->simple_query(qq[
        CREATE TABLE _jifty_uuids (
            uuid        char(36),
            row_table   varchar(255),
            row_id      integer
        )
    ]);
    $self->simple_query(qq[
        CREATE UNIQUE INDEX JiftyUUID ON _jifty_uuids (uuid, row_table, row_id)
    ]);
    $self->simple_query(qq[
        CREATE UNIQUE INDEX JiftyUUID_Row ON _jifty_uuids (row_table, row_id)
    ]);
    $self->simple_query(qq[
        CREATE UNIQUE INDEX JiftyUUID_UUID ON _jifty_uuids (uuid)
    ]);
}

=head2 insert_uuids_for_existing_rows 

Called by the upgrade script to create UUIDs for existing rows. Could be called at any time to create UUIDs for any rows that don't already have them.

=cut

sub insert_uuids_for_existing_rows {
    my $self = shift;

    # Iterate over all models
    for my $model (Jifty->class_loader->models) {
        # If the model isn't a record, ignore it
        next unless $model->isa('Jifty::Record');

        # Load the collection for the model
        my $collection = $model . 'Collection';
        $collection->require;

        # Create an unlimited instance of the collection
        my $records = $collection->new;
        $records->unlimit;

        # Iterate over all the records in the collection
        while (my $record = $records->next) {

            # Lookup UUID will create one if it doesn't exist
            my $uuid = $self->lookup_uuid($model->table, $record->id);
        }
    }    
}

=head2 lookup_uuid($table, $id)

Look up the UUID for a given row.

=cut

sub lookup_uuid {
    my ($self, $table, $id) = @_;

    # No UUIDs unless RecordUUIDs is turned on (lazy or active will do)
    return undef unless ( Jifty->config->framework('Database')->{'RecordUUIDs'} ne 'off');

    # Look for an existing UUID first
    my ($uuid) = $self->fetch_result(qq[ SELECT uuid FROM _jifty_uuids WHERE row_table = ? AND row_id = ?  ], $table, $id);

    # If none found, create it
    unless ($uuid) {
        $uuid = $self->_insert_uuid( table => $table, id => $id);
    }

    return $uuid;
}

=head2 lookup_record($uuid)

Performs the reverse operation of the above. It returns an instance of the record represented by the given UUID. Returns C<undef> if no record matching the given UUID is found.

=cut

# XXX sterling: Is this really implemented in the best way? Particularly the
# record class lookup?

# XXX sterling: Should this return a Class::ReturnValue or something else?
sub lookup_record {
    my $self = shift;
    my $uuid = shift;

    # Lookup the table name and ID
    my ($table, $id) = $self->fetch_result(qq[ SELECT row_table, row_id FROM _jifty_uuids WHERE uuid = ? ], $uuid);

    return unless defined $table and defined $id;

    # Find the record class for the table
    my ($record_class) = grep { $_->table eq $table } 
                              Jifty->class_loader->models;

    # If still not defined, check to see if this is ModelClass/ModelClassColumn
    # XXX Should these be placed in Jifty->class_load->models? -- sterling
    if (not defined $record_class) {
        if ($table eq '_jifty_models') {
            $record_class = 'Jifty::Model::ModelClass';
        }
        elsif ($table eq '_jifty_modelcolumns') {
            $record_class = 'Jifty::Model::ModelClassColumn';
        }
    }

    return unless defined $record_class;
    
    # Only return a value when load succeeds
    my $instance = $record_class->new;
    if ($instance->load($id)) {
        return $instance;
    }

    # Otherwise, return undef
    else {
        return;
    }
}

sub _upgrade_schema {
    my $self = shift;
    my $hack = {};
    require Jifty::Script::Schema;
    bless $hack, "Jifty::Script::Schema";
    $hack->run_upgrades;

}

=head1 AUTHOR

Various folks at BestPractical Solutions, LLC.

=cut

1;
