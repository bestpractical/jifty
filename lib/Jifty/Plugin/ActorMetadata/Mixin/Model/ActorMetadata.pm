use strict;
use warnings;

package Jifty::Plugin::ActorMetadata::Mixin::Model::ActorMetadata;
use Jifty::DBI::Schema;
use base 'Jifty::DBI::Record::Plugin';

our @EXPORT = qw(current_user_can);

=head1 NAME

Jifty::Plugin::ActorMetadata::Mixin::Model::ActorMetadata - ActorMetadata mixin

=head1 SYNOPSIS

  package MyApp::Model::CoffeeShop;
  use Jifty::DBI::Schema;
  use MyApp::Record schema {
      # custom column defrinitions
  };

  use Jifty::Plugin::ActorMetadata::Mixin::Model::ActorMetadata; # created_by, created_on, updated_on

=head1 DESCRIPTION

=head1 SCHEMA

This mixin adds the following columns to the model schema:

=head2 created_by

=head2 created_on

=head2 updated_on

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

sub before_create {
    my $self = shift;
    my $args = shift;

    $args->{'created_by'} = $self->current_user->id;
    $args->{'created_on'} = $args->{'updated_on'} = Jifty::DateTime->now;

    return 1;
}

# XXX: Move this to an abortable trigger
sub current_user_can {
    my $self = shift;
    my $action = shift;
    my %args = (@_);

    if ($action eq 'create') {
        return undef unless ($self->current_user and $self->current_user->id);
    }

    if ($action eq 'update' or $action eq 'delete') {
        return undef unless ($self->current_user and $self->current_user->id eq $self->created_by->id);
    }

    return 1;
}

1;
