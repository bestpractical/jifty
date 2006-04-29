use warnings;
use strict;

=head1 NAME

Jifty::Model::Metadata - Tracks Jifty-related metadata

=head1 SYNOPSIS

  my $app = Jifty->new(config_file => "$ProjectRoot/etc/config.yml");
  my $application_version = Jifty::Model::Metadata->load("application_db_version");

=head1 DESCRIPTION

Every Jifty application automatically inherits this table, which
describes information about the Jifty database.  It uses this
information to smartly upgrade between application versions, as well
as versions of Jifty itself, for instance.

=cut

package Jifty::Model::Metadata::Schema;
use Jifty::DBI::Schema;

column key   => type is 'text';
column value => type is 'text';

package Jifty::Model::Metadata;
use version;

use base qw( Jifty::Record );

=head2 table

Schemas are stored in the table C<_jifty_metadata>.

=cut

sub table {'_jifty_metadata'}

=head2 since

The metadata table first appeared in Jifty version 0.60427

=cut

sub since {'0.60427'}

=head2 load KEY

Fetches the given C<KEY> from the metadata store.  Returns undef if
such a key cannot be found.

=cut

sub load {
    my $self = shift;
    $self = $self->new( current_user => Jifty::CurrentUser->superuser )
        unless ref $self;
    return undef unless $self->_handle and $self->_handle->dbh->ping;

    my ($key) = @_;

    # This may barf all over the place.  That's almost expected in
    # some circumstances, so we eat all warnings and errors right
    # here, right now.
    eval {
        local $SIG{__WARN__} = sub { };
        $self->load_by_cols( key => $key );
    };
    return undef unless $self->id;
    return $self->value;
}

=head2 store KEY => VALUE

Stores the given C<KEY> in the database, overwriting the previous
value if it existed.

=cut

sub store {
    my $self = shift;
    $self = $self->new( current_user => Jifty::CurrentUser->superuser )
        unless ref $self;

    my ( $key, $value ) = @_;
    $self->load_by_cols( key => $key );
    if ( $self->id ) {
        $self->set_value($value);
    } else {
        $self->create( key => $key, value => $value );
    }
}

1;
