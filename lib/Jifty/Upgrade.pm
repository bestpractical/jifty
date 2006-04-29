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
@EXPORT = qw/since/;

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

1;
