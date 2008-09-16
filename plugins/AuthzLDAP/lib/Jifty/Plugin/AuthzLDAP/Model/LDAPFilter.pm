package Jifty::Plugin::AuthzLDAP::Model::LDAPFilter;
use Jifty::DBI::Schema;
use Scalar::Defer;

our $VERSION = '0.02';

=head1 NAME

Jifty::Plugin::AuthzLDAP::Model::LDAPFilter - model for filters

=cut

use Jifty::Record schema {
column
  name => type is 'text',
  label is 'Name',
  is mandatory,
  is distinct;

column
  ldapfilter => type is 'text',
  label is 'Filter',
  is mandatory;

column
   is_group => type is 'boolean',
   label is 'Group';

column 'created_on' =>
  type is 'datetime',
  is immutable,
  default is defer { DateTime->now },
  filters are 'Jifty::DBI::Filter::DateTime';
};

=head2 create

=cut

sub create {
    my $self  = shift;
    my %args  = (@_);
    my (@ret) = $self->SUPER::create(%args);

    return (@ret);
}


=head2 current_user_can ACTION

 Only superuser can create or edit filters.
 Logged-in users can read. 

=cut

sub current_user_can {
    my $self = shift;
    my $type = shift;

    if ($type eq 'create' || $type eq 'update') {
        return 0 if
           !$self->current_user->is_superuser;
        return 1;
    } elsif($type eq 'read') {
        return 1 if 
            $self->current_user->id || $self->current_user->is_superuser;
        return 0;
    }

    return $self->SUPER::current_user_can($type, @_);
}

=head1 AUTHOR

Yves Agostini, <yvesago@cpan.org>

=head1 LICENSE

Copyright 2007-2008 Yves Agostini. All Rights Reserved.

This program is free software and may be modified and distributed under the same terms as Perl itself.

=cut

1;
