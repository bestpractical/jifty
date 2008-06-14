#!/usr/bin/env perl
use strict;
use warnings;

package Jifty::Plugin::Attributes::Model::Attribute;
use base 'Jifty::Record';

=head1 NAME

Jifty::Plugin::Attributes::Model::Attribute - Attribute model

=cut

use Jifty::DBI::Schema;
use Jifty::Record schema {
    column name =>
        type is 'text',
        is mandatory;

    column description =>
        type is 'text';

    column content =>
        type is 'blob',
        filters are 'Jifty::DBI::Filter::Storable';

    column object_type =>
        type is 'text',
        is mandatory;

    column object_id =>
        type is 'int',
        is mandatory;
};

=head2 before_create

Let users pass in object instead of object_type and object_id.

=cut

sub before_create {
    my $self = shift;
    my $args = shift;

    if (my $object = delete $args->{object}) {
        $args->{object_type} = ref($object);
        $args->{object_id}   = $object->id;
    }

    return 1;
}

=head2 current_user_can

If you can read the original object, you can read its attributes. If you can
update the original object, you can create, update, and delete its attributes.

=cut

sub current_user_can {
    my $self  = shift;
    my $right = shift;

    # get a copy of the object
    my ($type, $id);

    if ($right eq 'create') {
        my %args = @_;
        ($type, $id) = $args{object}
                     ? (ref($args{object}), $args{object}->id)
                     : ($args{object_type}, $args{object_id});
    }
    else {
        ($type, $id) = ($self->__value('object_type'), $self->__value('object_id'));
    }

    Carp::confess "No object given!" if !defined($type);

    my $object = $type->new;
    $object->load($id);

    if ($right ne 'read') {
        $right = 'update';
    }

    return $object->current_user_can($right, @_);
}

=head2 object

Returns the object that owns this attribute.

=cut

sub object {
    my $self = shift;
    my ($type, $id) = ($self->object_type, $self->object_id);

    my $object = $type->new;
    $object->load($id);

    return $object;
}

1;

