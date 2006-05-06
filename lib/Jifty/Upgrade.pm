use warnings;
use strict;

=head1 NAME

Jifty::Upgrade

=head1 DESCRIPTION

C<Jifty::Upgrade> is an abstract baseclass to use to customize schema
and data upgrades that happen.

=cut

package Jifty::Upgrade;

use base qw/Jifty::Object Exporter/;
use vars qw/%UPGRADES @EXPORT/;
@EXPORT = qw/since rename/;

=head2 since I<VERSION> I<SUB>

C<since> is meant to be called by subclasses of C<Jifty::Upgrade>.
Calling it signifies that I<SUB> should be run when upgrading to
version I<VERSION>, after tables and columns are added, but before
tables and columns are removed.  If multiple subroutines are given for
the same version, they are run in order that they were set up.

=cut

sub since {
    my ($version, $sub) = @_;
    my $package = (caller)[0];
    if (exists $UPGRADES{$package}{$version}) {
        $UPGRADES{$package}{$version} = sub { $UPGRADES{$package}{$version}->(); $sub->(); }
    } else {
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
    return sort keys %{$UPGRADES{$class} || {}};
}

=head2 upgrade_to I<VERSION>

Runs the subroutine that has been registered for the given version; if
no subroutine was registered, returns a no-op subroutine.

=cut

sub upgrade_to {
    my $class = shift;
    my $version = shift;
    return $UPGRADES{$class}{$version} || sub {};
}

=head2 rename table => CLASS, [column => COLUMN,] to => NAME

Used in upgrade subroutines, this executes the necessary SQL to rename
the table, or column in the table, to a new name.

=cut

sub rename {
    my (%args) = @_;

    $args{table} ||= $args{in};
    die "Must provide a table to rename" unless $args{table};

    Jifty::Util->require($args{table});
    $args{table} = $args{table}->table;

    if ($args{column}) {
        my $driver = Jifty->config->framework('Database')->{'Driver'};
        if ($driver eq "SQLite") {
            # It's possible to work around this, but it's a PITA that
            # I haven't figured out all of the details of.  It
            # involves creating a temporary table that's a duplicate
            # of the current table, copying the data over, dropping
            # the original table, recreating it with the column
            # renamed, transferring the data back, and then dropping
            # the temporary table.  Painful enough for ya?
            die "SQLite does not support renaming columns in tables.  We are sad!";
        } else {
            Jifty->handle->simple_query("ALTER TABLE $args{table} RENAME $args{column} TO $args{to}");
        }
    } else {
        Jifty->handle->simple_query("ALTER TABLE $args{table} RENAME TO $args{to}");
    }
}

1;
