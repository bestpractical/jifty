use strict;
use warnings;

package Jifty::Plugin::ActorMetadata::Mixin::Model::ActorMetadata;
use Jifty::DBI::Schema;
use base 'Jifty::DBI::Record::Plugin';

our @EXPORT = qw(current_user_can current_user_is_owner);
my %column_names;

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
BEGIN {

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

=head1 METHODS

# XXX: pod coverage should count parent classes.  this pod is useless

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

    return
      unless $column_names{ ref $self || $self }{'updated_on'}
          && $column eq $column_names{ ref $self || $self }{'updated_on'}
          || $column_names{ ref $self || $self }{'updated_by'}
          && $column eq $column_names{ ref $self || $self }{'updated_by'};

    $self->add_trigger(name => 'after_set', callback => \&after_set);
    return 1;
}

=head2 before_create

Sets C<created_by>, C<created_on>, C<updated_on> and C<updated_by> based on the current user and time.

=cut

sub before_create {
    my $self = shift;
    my $args = shift;
    for my $by (qw/created_by updated_by/) {
        if ( $column_names{ ref $self || $self }{$by} ) {
            $args->{$column_names{ ref $self || $self }{$by}} ||= $self->current_user->id;
        }
    }

    for my $time ( qw/created_on updated_on/ ) {
        if ( $column_names{ ref $self || $self }{$time} ) {
            $args->{$column_names{ ref $self || $self }{$time}} ||= Jifty::DateTime->now;
        }
    }

    return 1;
}

=head2 after_set

update C<updated_on> and C<updated_by> based on the current user and current time.

=cut

sub after_set {
    my $self = shift;
    if ( $column_names{ ref $self || $self }{'updated_on'} ) {
        $self->__set(
            column => $column_names{ ref $self || $self }{'updated_on'},
            value  => Jifty::DateTime->now
        );
    }
    if ( $column_names{ ref $self || $self }{'updated_by'} ) {
        $self->__set(
            column => $column_names{ ref $self || $self }{'updated_by'},
            value  => $self->current_user->id
        );
    }

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
        return
          unless $self->current_user
            and $self->current_user->id
            || $self->current_user->is_bootstrap_user;
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

    my $created_by = $self->__value($column_names{ref $self || $self}{'created_by'});
    return unless $self->current_user && $created_by;

    return unless $self->current_user->id;

    return $self->current_user->id == $created_by;
}

=head2 import

to be more flexible, we allow some configurations like:
e.g.
use Jifty::Plugin::ActorMetadata::Mixin::Model::ActorMetadata 
    user_class => 'Foo::Model::Principal',
    map => { created_by => 'creator', created_on => 'created' }

current valid args are:
user_class => 'Foo::Model::User'  
        class that you want created_by and updated_by to be refers_to
map => { created_by => 'creator', ... }
        the real column name you want to use. this also controls whether
        a column will be added or not. i.e. if the hashref is 
        { created_by => 'creator', created_on => 'created' }, then columns
        'updated_by' and 'updated_on' will not be added.

=cut

sub import {
    my $self = shift;
    my %args = @_;
    my $user_class = $args{'user_class'} || Jifty->app_class('Model', 'User');

    my @columns = qw/created_on created_by updated_on updated_by/;
    my %map;

    # fiddle map
    if ( $args{'map'} && ref $args{'map'} eq 'HASH' ) {
        for my $column ( keys %{$args{'map'}} ) {
            $map{$column} = $args{'map'}{$column};
        }
    }
    else {
        @map{@columns} = @columns;
    }

    $column_names{scalar caller} = \%map;

    Jifty::DBI::Schema->import; # to import subs like schema, references
    my @ret = schema {
        if ( $map{'created_by'} ) {
            column $map{'created_by'} => references $user_class, 
                render_as 'hidden';
        }
        if ( $map{'created_on'} ) {
            column $map{'created_on'} => is TimeStamp,
                render_as 'hidden';
        }
        if ( $map{'updated_by'} ) {
            column $map{'updated_by'} => references $user_class,
                render_as 'hidden';
        }
        if ( $map{'updated_on'} ) {
            column $map{'updated_on'} => is TimeStamp,
                render_as 'hidden';
        }
    };
    require Jifty::Record;
    Jifty::Record->import( @ret );
    
# TODO
# below is the import sub from Jifty::DBI::Record::Plugin, 
# because of some caller stuff, I can't just call SUPER
# need to refactor, either here or Jifty::DBI::Record::Plugin
    my $caller = caller;

    for ($self->columns) {
        $caller->_init_methods_for_column($_);
        # virtual will be handled later
        $caller->COLUMNS->{$_->name} = $_ unless $_->virtual;
    }
    $self->export_to_level(1,undef);

    if (my $triggers =  $self->can('register_triggers') ) {
        $triggers->($caller)
    }

    if (my $triggers_for_column =  $self->can('register_triggers_for_column') ) {
        for my $column (keys %{$caller->_columns_hashref}) {
            $triggers_for_column->($caller, $column)
        }
    }
    push(@{ $caller->RECORD_MIXINS }, $self);
    $self->COLUMNS(undef); # reset columns for ActorMetadata.pm
}

1;
