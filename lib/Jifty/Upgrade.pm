use warnings;
use strict;

=head1 NAME

Jifty::Upgrade - Superclass for schema/data upgrades to Jifty applicaitons

=head1 SYNOPSIS

  package MyApp::Upgrade;

  use base qw/ Jifty::Upgrade /;
  use Jifty::Upgrade qw/ since rename /;

  since '0.7.4' => sub {
      # Rename a column
      rename table => 'cthulus', name => 'description', 
                                   to => 'mind_numbingly_horrible_word_picture';
  };

  since '0.6.1' => sub {
      my @sizes       = ('Huge', 'Gigantic', 'Monstrous', 'Really Big');
      my @appearances = ('Horrible', 'Disgusting', 'Frightening', 'Evil');
      
      # populate new columns with some random stuff
      my $cthulus = MyApp::Model::CthuluCollection->new;
      while (my $cthulu = $cthulus->next) {
          $cthulu->set_size($sizes[ int(rand(@sizes)) ]);
          $cthulu->set_appearance($sizes[ int(rand(@appearances)) ]);
      }
  };

=head1 DESCRIPTION

C<Jifty::Upgrade> is an abstract baseclass to use to customize schema
and data upgrades that happen.

=cut

package Jifty::Upgrade;

use base qw/Jifty::Object Exporter Class::Data::Inheritable/;
use vars qw/%UPGRADES @EXPORT/;
@EXPORT = qw/since rename/;

__PACKAGE__->mk_classdata('just_renamed');

=head2 since I<VERSION> I<SUB>

C<since> is meant to be called by subclasses of C<Jifty::Upgrade>.
Calling it signifies that I<SUB> should be run when upgrading to
version I<VERSION>, after tables and columns are added, but before
tables and columns are removed.  If multiple subroutines are given for
the same version, they are run in order that they were set up.

=cut

sub since {
    my ( $version, $sub ) = @_;
    my $package = (caller)[0];
    if ( exists $UPGRADES{$package}{$version} ) {
        $UPGRADES{$package}{$version} =
          sub { $UPGRADES{$package}{$version}->(); $sub->(); }
    }
    else {
        $UPGRADES{$package}{$version} = $sub;
    }
}

=head2 versions

Returns the list of versions that have been registered; this is called
by the L<Jifty::Script::Schema> tool to determine what to do while
upgrading.

=cut

sub versions {
    my $class = shift;
    return sort keys %{ $UPGRADES{$class} || {} };
}

=head2 upgrade_to I<VERSION>

Runs the subroutine that has been registered for the given version; if
no subroutine was registered, returns a no-op subroutine.

=cut

sub upgrade_to {
    my $class   = shift;
    my $version = shift;
    return $UPGRADES{$class}{$version} || sub { };
}

=head2 rename table => CLASS, [column => COLUMN,] to => NAME

Used in upgrade subroutines, this executes the necessary SQL to rename
the table, or column in the table, to a new name.

=cut

sub rename {
    my (%args) = @_;

    $args{table} ||= $args{in};
    die "Must provide a table to rename" unless $args{table};

    Jifty::Util->require( $args{table} );
    my $table_name = $args{table}->table;

    my $package = (caller)[0];
    my $renamed = $package->just_renamed || {};

    if ( $args{column} ) {
        my $driver = Jifty->config->framework('Database')->{'Driver'};
        if ( $driver =~ /SQLite/ ) {

            # Convert columns
            my ($schema) = Jifty->handle->fetch_result("SELECT sql FROM sqlite_master WHERE tbl_name = '$table_name' AND type = 'table'");

            $schema =~ s/(.*create\s+table\s+)\S+(.*?\(\s*)//i or die "Cannot find 'CREATE TABLE' statement in schema for '$table_name': $schema";

            my $new_table_name    = join( '_', $table_name, 'new', $$ );
            my $new_create_clause = "$1$new_table_name$2";

            my @column_info = ( split /,/, $schema );
            my @column_names = map { /^\s*(\S+)/ ? $1 : () } @column_info;

            s/^(\s*)\b\Q$args{column}\E\b/$1$args{to}/i for @column_info;

            my $new_schema = $new_create_clause . join( ',', @column_info );
            my $copy_columns = join(
                ', ',
                map {
                    ( lc($_) eq lc( $args{column} ) )
                      ? "$_ AS $args{to}"
                      : $_
                  } @column_names
            );

            # Convert indices
            my $indice_sth = Jifty->handle->simple_query("SELECT sql FROM sqlite_master WHERE tbl_name = '$table_name' AND type = 'index'");
            my @indice_sql;
            while ( my ($index) = $indice_sth->fetchrow_array ) {
                $index =~ s/^(.*\(.*)\b\Q$args{column}\E\b/$1$args{to}/i;
                push @indice_sql, $index;
            }
            $indice_sth->finish;

            # Run the conversion SQLs
            Jifty->handle->begin_transaction;
            Jifty->handle->simple_query($new_schema);
            Jifty->handle->simple_query("INSERT INTO $new_table_name SELECT $copy_columns FROM $table_name");
            Jifty->handle->simple_query("DROP TABLE $table_name");
            Jifty->handle->simple_query("ALTER TABLE $new_table_name RENAME TO $table_name");
            Jifty->handle->simple_query($_) for @indice_sql;
            Jifty->handle->commit;
        }
        else {
            Jifty->handle->simple_query("ALTER TABLE $table_name RENAME $args{column} TO $args{to}");
        }

        # Mark this table column as renamed
        $renamed->{ $table_name }{'drop'}{ $args{'column'} } = $args{'to'};
        $renamed->{ $table_name }{'add' }{ $args{'to'    } } = $args{'column'};
    }
    else {
        Jifty->handle->simple_query("ALTER TABLE $table_name RENAME TO $args{to}");

        # Mark this table as renamed
        $renamed->{ $table_name }{'drop_table'} = $args{'to'};
        $renamed->{ $args{'to'} }{'add_table' } = $table_name;
    }

    # Remember renames so that adds/drops are canceled
    $package->just_renamed($renamed);
}



=head1 SEE ALSO

L<Jifty::Manual::Upgrading>

=cut

1;
