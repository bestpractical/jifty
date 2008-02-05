#!/usr/bin/env perl
package Jifty::Plugin::Attributes::Mixin::Attributes;
use strict;
use warnings;
use Jifty::Plugin::Attributes::Model::Attribute;
use Jifty::Plugin::Attributes::Model::AttributeCollection;

use base 'Exporter';

our @EXPORT = qw/attributes first_attribute add_attribute set_attribute
                 delete_attribute/;

=head2 attributes

Returns an AttributeCollection limited to the invoking object.

=cut

sub attributes {
    my $self = shift;
    my $attrs = Jifty::Plugin::Attributes::Model::AttributeCollection->new;
    $attrs->limit_to_object($self);
}

=head2 first_attribute name

Returns the first attribute on this object with the given name.

=cut

sub first_attribute {
    my $self = shift;
    my $name = shift;

    $self->attributes->named($name)->first;
}

=head2 add_attribute PARAMHASH

Adds the given attribute to this object. The following fields must be
provided:

=over 4

=item name

The name of the attribute

=item description

A description of the attribute

=item content

The attribute's value

=back

=cut

sub add_attribute {
    my $self = shift;
    my %args = @_;

    my $attr = Jifty::Plugin::Attributes::Model::Attribute->new;
    $attr->create(
        object      => $self,
        name        => $args{name},
        description => $args{description},
        content     => $args{content},
    );
}

=head2 set_attribute PARAMHASH

Sets the given attribute on the object. Note that all existing attributes of
that name will be removed. The following fields must be provided:

=over 4

=item name

The name of the attribute

=item description

A description of the attribute

=item content

The attribute's value

=back

=cut

sub set_attribute {
    my $self = shift;
    my %args = @_;

    my $attrs = $self->attributes->named($args{name});
    if ($attrs->count == 0) {
        return $self->add_attribute(%args);
    }

    my $saved = $attrs->first;

    while (my $attr = $attrs->next) {
        $attr->delete;
    }

    $saved->set_content($args{content});
    $saved->set_description($args{description});

    return $saved;
}

=head2 delete_attribute name

Deletes all attributes of the given name

=cut

sub delete_attribute {
    my $self = shift;
    my $name = shift;

    my $attrs = $self->attributes->named($name);
    while (my $attr = $attrs->next) {
        $attr->delete;
    }
}

1;

