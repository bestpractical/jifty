package Jifty::Plugin::Authentication::Ldap::Mixin::Model::User;
use strict;
use warnings;
use Jifty::DBI::Schema;
use base 'Jifty::DBI::Record::Plugin';
use URI;

=head1 NAME

Jifty::Plugin::Authentication::Ldap::Mixin::Model::User - Ldap mixin with User model

=head1 DESCRIPTION

L<Jifty::Plugin::Authentication::Ldap> mixin for the User model.  Provides an 'ldap_id' column.

=cut

our @EXPORT = qw(has_alternative_auth);

use Jifty::Plugin::Authentication::Ldap::Record schema {

column ldap_id =>
  type is 'text',
  label is 'Ldap ID',
  is distinct;
  #is immutable;

};

=head2 has_alternative_auth

=cut

sub has_alternative_auth { 1 }

1;
