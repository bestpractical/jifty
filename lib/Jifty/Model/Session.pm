use warnings;
use strict;

=head1 NAME

Jifty::Model::Session - Tracks in-db session version

=head1 SYNOPSIS

  my $app = Jifty->new(config_file => "$ProjectRoot/etc/config.yml");
  my $session = Jifty::Model::Session->new;
  my $db_version = $session->in_db;

=head1 DESCRIPTION

Every Jifty application automatically inherits this table, which
describes what version of the session is in the database currently.
This allows Jifty to smartly upgrade between session versions.

=cut

package Jifty::Model::Session::Session;
use Jifty::DBI::Session;


column session_id => type is 'varchar(32)';
column key => type is 'text';
column value => type is 'text';
column created => type is 'date';
column updated => type is 'date';
column key_type => type is varchar('32');

package Jifty::Model::Session;
use version;

use base qw( Jifty::Record );

=head2 table

Sessions are stored in the table C<_jifty_sessions>.

=cut

sub table { '_jifty_sessions' }

sub _init { } # we really don't need a current_user for this


sub 

1;
