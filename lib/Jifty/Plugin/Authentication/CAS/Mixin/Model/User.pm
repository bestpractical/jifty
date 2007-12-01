package Jifty::Plugin::Authentication::CAS::Mixin::Model::User;
use strict;
use warnings;
use Jifty::DBI::Schema;
use base 'Jifty::DBI::Record::Plugin';

=head1 NAME

Jifty::Plugin::Authentication::CAS::Mixin::Model::User;

=head1 DESCRIPTION

L<Jifty::Plugin::Authentication::CAS> mixin for the User model.  Provides an 'cas_id' column.

=cut

our @EXPORT = qw(has_alternative_auth);

use Jifty::Plugin::Authentication::CAS::Record schema {

column cas_id =>
  type is 'text',
  label is 'CAS ID',
  is distinct,
  is immutable;

};

=head2 has_alternative_auth

=cut

sub has_alternative_auth { 1 }

1;
