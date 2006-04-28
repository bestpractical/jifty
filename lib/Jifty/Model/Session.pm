use warnings;
use strict;

=head1 NAME

Jifty::Model::Session - Jifty session tracking

=head1 DESCRIPTION

Every Jifty application automatically inherits this table, which
tracks session information for the application.  Individual keys in
the session structure are stored as rows, making session updates take
constant time, and also reducing the need for locking.

=cut

package Jifty::Model::Session::Schema;
use Jifty::DBI::Schema;

column session_id => type is 'varchar(32)';
column key => type is 'text';
column value => type is 'blob',
  filters are 'Jifty::DBI::Filter::Storable';
column created => type is 'timestamp',
  filters are 'Jifty::DBI::Filter::DateTime';
column updated => type is 'timestamp',
  filters are 'Jifty::DBI::Filter::DateTime';
column key_type => type is 'varchar(32)';

package Jifty::Model::Session;

use base qw( Jifty::Record );
use DateTime;

=head2 table

Sessions are stored in the table C<_jifty_sessions>.

=cut

sub table {'_jifty_sessions'}
sub since { '0.60428' }
sub current_user { return Jifty::CurrentUser->superuser }

=head2 new_session_id

Returns a random new session id.  This is a 32-character hex string.

=cut

sub new_session_id {
    return Digest::MD5::md5_hex(
        Digest::MD5::md5_hex( time() . {} . rand() . $$ ) );
}

=head2 create

Defaults the created and updated times to now.

=cut

sub create {
    my $self = shift;
    my %args = (
        session_id => $self->new_session_id,
        key_type   => "key",
        created    => DateTime->now,
        updated    => DateTime->now,
        @_,
    );

    return $self->SUPER::create(%args);
}

=head2 set_value [VALUE]

Updates the C<updated> column, in addition to setting the value.

=cut

sub set_value {
    my $self  = shift;
    my $value = shift;

    return undef unless $self->id;

    $self->set_updated( DateTime->now );
    $self->_set( column => 'value', value => $value );
}

1;
