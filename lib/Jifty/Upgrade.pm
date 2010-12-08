use warnings;
use strict;

=head1 NAME

Jifty::Upgrade - Superclass for schema/data upgrades to Jifty applications

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
          $cthulu->set_appearance($appearances[ int(rand(@appearances)) ]);
      }
  };

=head1 DESCRIPTION

C<Jifty::Upgrade> is an abstract base class to use to customize schema
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

        Jifty->handle->rename_column( %args, table => $table_name );

        # Mark this table column as renamed
        $renamed->{ $table_name }{'drop'}{ $args{'column'} } = $args{'to'};
        $renamed->{ $table_name }{'add' }{ $args{'to'    } } = $args{'column'};
    }
    else {
        Jifty->handle->rename_table( %args, table => $table_name );

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
