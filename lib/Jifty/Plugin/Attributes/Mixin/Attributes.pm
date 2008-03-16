#!/usr/bin/env perl
package Jifty::Plugin::Attributes::Mixin::Attributes;
use strict;
use warnings;
use Jifty::Plugin::Attributes::Model::Attribute;
use Jifty::Plugin::Attributes::Model::AttributeCollection;

use base 'Exporter';

our @EXPORT = qw/attributes first_attribute add_attribute set_attribute
                 delete_attribute delete_all_attributes/;

=head2 attributes

Returns an AttributeCollection limited to the invoking object.

=cut

sub attributes {
    my $self = shift;
    my $attrs = Jifty::Plugin::Attributes::Model::AttributeCollection->new;
    $attrs->limit_to_object($self);
}

=head2 first_attribute name

Returns the first attribute on this object with the given name, or C<undef> if
none exist.

=cut

sub first_attribute {
    my $self = shift;
    my $name = shift;

    $self->attributes->named($name)->first;
}

=head2 add_attribute PARAMHASH

Adds the given attribute to this object. Returns the new attribute if
successful, C<undef> otherwise. The following fields must be provided:

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

    return $attr->id ? $attr : undef;
}

=head2 set_attribute PARAMHASH

Sets the given attribute on the object. Note that all existing attributes of
that name will be removed. Returns the new attribute or C<undef> if one could
not be created. The following fields must be provided:

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

Deletes all attributes of the given name. Returns a true value if all attributes
were deleted, a false if any could not be.

=cut

sub delete_attribute {
    my $self = shift;
    my $name = shift;
    my $ok = 1;

    my $attrs = $self->attributes->named($name);
    while (my $attr = $attrs->next) {
        $attr->delete
            or $ok = 0;
    }

    return $ok;
}

=head2 delete_all_attributes

Deletes all the attributes associated with the object.

=cut

sub delete_all_attributes {
    my $self = shift;
    my $ok = 1;

    my $attrs = $self->attributes;
    while (my $attr = $attrs->next) {
        $attr->delete
            or $ok = 0;
    }

    return $ok;
}

1;

