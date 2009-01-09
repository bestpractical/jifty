use strict;
use warnings;

package Jifty::Plugin::ActorMetadata::Mixin::Model::ActorMetadata;
use Jifty::DBI::Schema;
use base 'Jifty::DBI::Record::Plugin';

our @EXPORT = qw(current_user_can current_user_is_owner);

=head1 NAME

Jifty::Plugin::ActorMetadata::Mixin::Model::ActorMetadata - ActorMetadata mixin

=head1 SYNOPSIS

  package MyApp::Model::CoffeeShop;
  use Jifty::DBI::Schema;
  use MyApp::Record schema {
      # custom column defrinitions
  };

  use Jifty::Plugin::ActorMetadata::Mixin::Model::ActorMetadata; # created_by, created_on, updated_on and updated_by

=head1 DESCRIPTION

=head1 SCHEMA

This mixin adds the following columns to the model schema:

=head2 created_by

=head2 created_on

=head2 updated_on

=head2 updated_by

=cut

# XXX: move this to somewhere
my $app_user;
BEGIN {

# Do not call ->app_class within the schmea {} block.
$app_user = Jifty->app_class('Model', 'User');
Jifty::DBI::Schema->register_types(
    Date =>
        sub { type is 'date', input_filters are qw/Jifty::DBI::Filter::Date/ },
    Time =>
        sub { type is 'time', input_filters are qw/Jifty::DBI::Filter::Time/ },
    DateTime => sub {
        type is 'datetime',
        input_filters are qw/Jifty::DBI::Filter::DateTime/ },
    TimeStamp => sub {
        type is 'timestamp',
        filters are qw( Jifty::Filter::DateTime Jifty::DBI::Filter::DateTime),
    }
);
}

use Jifty::Record schema {

column created_by =>
  render_as 'hidden',
  refers_to $app_user;

column updated_by =>
#refers_to $app_user, # TODO this weirdly doesn't work, need dig
  render_as 'hidden';

column created_on => is TimeStamp,
  render_as 'hidden';
column updated_on => is TimeStamp,
  render_as 'hidden';

};

=head1 METHODS

# XXX: podcoverage should count parent classes.  these pods are useless

=head2 register_triggers

Adds the triggers to the model this mixin is added to.

=cut

sub register_triggers {
    my $self = shift;
    $self->add_trigger(name => 'before_create', callback => \&before_create);
}

=head2 register_triggers_for_column

=cut

sub register_triggers_for_column {
    my $self   = shift;
    my $column = shift;

    return unless $column eq 'updated_on' || $column eq 'updated_by';

    $self->add_trigger(name => 'after_set', callback => \&after_set);
    return 1;
}

=head2 before_create

Sets C<created_by>, C<created_on>, C<updated_on> and C<updated_by> based on the current user and time.

=cut

sub before_create {
    my $self = shift;
    my $args = shift;

    $args->{'created_by'} = $args->{'updated_by'} = $self->current_user->id;
    $args->{'created_on'} = $args->{'updated_on'} = Jifty::DateTime->now;

    return 1;
}

=head2 after_set

update C<updated_on> and C<updated_by> based on the current user and current time.

=cut

sub after_set {
    my $self = shift;
    $self->__set( column => 'updated_on', value => Jifty::DateTime->now );
    $self->__set( column => 'updated_by', value => $self->current_user->id );

    return 1;
}

=head2 current_user_can

Rejects creation unless there's a current_user. 

=cut

# XXX: Move this to an abortable trigger

sub current_user_can {
    my $self = shift;
    my $action = shift;
    my %args = (@_);

    if ($action eq 'create') {
        return undef unless ($self->current_user and $self->current_user->id);
    }

#Rejects update or deletion unless the current_user is the creator.  (Jesse says: this feels like wrong logic for this mixin)
#    if ($action eq 'update' or $action eq 'delete') {
#        return undef unless $self->current_user_is_owner;
#    }

    return 1;
}

=head2 current_user_is_owner

=cut

sub current_user_is_owner {
    my $self = shift;

    my $created_by = $self->__value('created_by');
    return unless $self->current_user && $created_by;

    return unless $self->current_user->id;

    return $self->current_user->id == $created_by;
}

1;
