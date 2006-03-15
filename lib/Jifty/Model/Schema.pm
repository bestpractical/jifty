use warnings;
use strict;

=head1 NAME

Jifty::Model::Schema - Tracks in-db schema version

=head1 SYNOPSIS

  my $app = Jifty->new(config_file => "$ProjectRoot/etc/config.yml");
  my $schema = Jifty::Model::Schema->new;
  my $db_version = $schema->in_db;

=head1 DESCRIPTION

Every Jifty application automatically inherits this table, which
describes what version of the schema is in the database currently.
This allows Jifty to smartly upgrade between schema versions.

=cut

package Jifty::Model::Schema::Schema;
use Jifty::DBI::Schema;

column major => type is 'integer';
column minor => type is 'integer';
column rev   => type is 'integer';


package Jifty::Model::Schema;
use version;

use base qw( Jifty::Record );

=head2 table

Schemas are stored in the table C<_db_version>.

=cut

sub table { '_db_version' }

sub _init { } # we really don't need a current_user for this

=head2 in_db

Returns the version of the schema that is stored in the database, as a
version object.

=cut

sub in_db {
  my $self = shift;
  my @v;
  if ($self->_handle and $self->_handle->dbh->ping) {
      # This may barf all over the place.  That's almost expected in
      # some circumstances, so we eat all warnings and errors right
      # here, right now.
      eval {
          local $SIG{__WARN__} = sub {};
          @v = $self->_handle->fetch_result("SELECT major, minor, rev FROM ".$self->table);
      };
  }
  return undef unless @v == 3; # No version in db yet
  return version->new(join (".", @v));
}

=head2 update VERSION

Updates the version number of the schema that is stored in the
database; VERSION should be a version object.  Note that this does not
actually update the tables and column themselves, merely the number
that is recorded as the current version!  See L<Jifty::Script::Schema>
for the program that updates schemas.

=cut

sub update {
  my $self = shift;
  my $ver = shift;

  unless ( eval { $ver->isa( 'version' ) } ) {
    $self->log->fatal("Version must be a version object");
    return;
  }

  my @v = map {s/\D//g; $_} split /\./, $ver->normal;
  $self->_handle->simple_query("DELETE FROM ".$self->table);
  # XXX TODO : Placeholders were broken for this on jesse's Pg host
  $self->_handle->simple_query("INSERT INTO ".$self->table." (major, minor, rev) VALUES (".join(", ", @v).")");
}

1;
