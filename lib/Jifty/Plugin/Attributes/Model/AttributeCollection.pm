#!/usr/bin/env perl
use strict;
use warnings;

package Jifty::Plugin::Attributes::Model::AttributeCollection;
use base 'Jifty::Collection';

=head2 record_class

Is this even required any more?

=cut

sub record_class { 'Jifty::Plugin::Attributes::Model::Attribute' }

=head2 named name

Limits to attributes with the given name.

=cut

sub named {
    my $self = shift;
    my $name = shift;

    $self->limit(column => 'name', value => $name);
    return $self;
}

=head2 limit_to_object object

Limits to attributes modifying the given object.

=cut

sub limit_to_object {
    my $self = shift;
    my $object = shift;

    my $type = ref($object); # should this check be smarter?
    return undef unless $type && $object->can('id');

    my $id = $object->id;

    $self->limit(column => 'object_type', value => $type);
    $self->limit(column => 'object_id', value => $id);

    return $self;
}

1;

