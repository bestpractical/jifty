use warnings;
use strict;

package Jifty::Handle::SVK;
use Jifty::Util;
use base 'Jifty::Handle';

=head1 NAME

Jifty::Handle::SVK -- Revision-controlled database handles for Jifty

=head1 SYNOPSIS

In your F<etc/config.yml>:

  framework:
    Database:
      HandleClass: Jifty::Handle::SVK

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    return $self;
}

sub connect {
    my $self = shift;
    my $rv = $self->SUPER::connect(@_);

    # Here we do it in SQL land to avoid circularity.
    local $SIG{__WARN__} = sub { 1 };
    defined $self->dbh->do(qq[
        CREATE TABLE _jifty_uuids (
            uuid        char(36),
            row_table   varchar(255),
            row_id      integer
        )
    ], { RaiseError => 0, PrintError => 0, AutoCommit => 1 } ) or return $rv;

    $self->dbh->do(qq[ CREATE UNIQUE INDEX JiftyUUID ON _jifty_uuids (uuid, row_table, row_id) ]);
    $self->dbh->do(qq[ CREATE UNIQUE INDEX JiftyUUID_Row ON _jifty_uuids (row_table, row_id) ]);
    $self->dbh->do(qq[ CREATE UNIQUE INDEX JiftyUUID_UUID ON _jifty_uuids (uuid) ]);

    return $rv;
}

sub create {
    my $self  = shift;
    my $table = shift;
    my $rv = $self->SUPER::create($table, @_);

    if ($rv) {
        # Generate a UUID on the sideband: $table - $rv - UUID.
        my $uuid = Jifty::Util->generate_uuid;
        $self->dbh->do(qq[ INSERT INTO _jifty_uuids VALUES (?, ?, ?) ], $uuid, $table, $rv);
    }

    return $rv;
}

sub delete {
    my $self = shift;
    my $rv = $self->SUPER::delete(@_);
    return $rv;
}

sub update_record_value {
    my $self = shift;
    my $rv = $self->SUPER::update_record_value(@_);
    return $rv;
}

sub begin_transaction {
    my $self = shift;
    my $rv = $self->SUPER::begin_transaction(@_);
    return $rv;
}

sub commit {
    my $self = shift;
    my $rv = $self->SUPER::commit(@_);
    return $rv;
}

sub rollback {
    my $self = shift;
    my $rv = $self->SUPER::rollback(@_);
    return $rv;
}

1;
