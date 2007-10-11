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

    my $driver = Jifty->config->framework('Database')->{'Driver'};
    if ($driver eq 'Oracle') {
        $ENV{'NLS_LANG'} = "AMERICAN_AMERICA.AL32UTF8";
        $ENV{'NLS_NCHAR'} = "AL32UTF8";
    }
   
    # We do this to avoid Jifty::DBI::Handle's magic reblessing, because
    # it breaks subclass methods.
    my $driver_class  = "Jifty::DBI::Handle::".  $driver;
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
    my $db_config = Jifty->config->framework('Database');

    # XXX TODO consider canonicalizing to all-lowercase, once there are no
    # legacy databases
    my $db = $db_config->{'Database'};

    if ($db_config->{'Driver'} =~ /SQLite/) {
        $db = Jifty::Util->absolute_path($db);
    } 

    return $db;
} 

=head2 connect ARGS

Like L<Jifty::DBI>'s connect method but pulls the name of the database
from the current L<Jifty::Config>.

=cut

sub connect {
    my $self = shift;
    my %args = (@_);
    my %db_config =  (%{Jifty->config->framework('Database')}, Database => $self->canonical_database_name);

    my %lc_db_config;
    # Skip the non-dsn keys, but not anything else
    for (grep {!/^checkschema|version|recordbaseclass|attributes$/i} keys %db_config) {
        $lc_db_config{lc($_)} = $db_config{$_};
    }
    $self->SUPER::connect( %lc_db_config , %args);
    $self->{db_config} = { %lc_db_config , %args };
    $self->dbh->{LongReadLen} = Jifty->config->framework('MaxAttachmentSize') || '10000000';

    # setup attributes
    my $attributes = Jifty->config->framework('Database')->{Attributes} || {};
    for (keys %$attributes) {
        $self->dbh->{lc($_)} = $attributes->{$_};
    }
}


=head2 check_schema_version

Make sure that we have a recent enough database schema.  If we don't,
then error out.

=cut

sub check_schema_version {
    require Jifty::Model::Metadata;

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
                $dbv = Jifty->handle->fetch_result(
                    "SELECT value FROM _jifty_metadata WHERE key = 'application_db_version'");
            } or undef($dbv);
        }

        die
            "Application schema has no version in the database; perhaps you need to run this:\n"
            . "\t bin/jifty schema --setup\n"
            unless defined $dbv;

        die
            "Application schema version in database ($dbv) doesn't match application schema version ($appv)\n"
            . "Please run `bin/jifty schema --setup` to upgrade the database.\n"
            unless version->new($appv) == version->new($dbv);
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
        die
            "Internal jifty schema version in database ($dbv) doesn't match running jifty version ($appv)\n"
            . "Please run `bin/jifty schema --setup` to upgrade the database.\n"
            unless $appv == $dbv;
    }

}


=head2 create_database MODE

C<MODE> is either "print" or "execute".

This method either prints the commands necessary to create the database
or actually creates it, depending on the value of MODE.

=cut

sub create_database {
    my $self = shift;
    my $mode = shift || 'execute';
    my $database = $self->canonical_database_name;
    my $driver   = Jifty->config->framework('Database')->{'Driver'};
    my $query = "CREATE DATABASE $database";
    $query .= " TEMPLATE template0" if $driver =~ /Pg/;
    if ( $mode eq 'print') {
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
    my $self = shift;
    my $mode = shift || 'execute';
    my $database = $self->canonical_database_name;
    my $driver   = Jifty->config->framework('Database')->{'Driver'};
    if ( $mode eq 'print' ) {
        print "DROP DATABASE $database;\n";
    } elsif ( $driver =~ /SQLite/ ) {

        # Win32 complains when you try to unlink open DB
        $self->disconnect if $^O eq 'MSWin32';
        unlink($database);
    } else {
        local $SIG{__WARN__} =
          sub { warn $_[0] unless $_[0] =~ /exist|couldn't execute/i };
        $self->simple_query("DROP DATABASE $database");
    }
}


=head1 AUTHOR

Various folks at BestPractical Solutions, LLC.

=cut

1;
