use strict;
use warnings;

package Jifty::CAS::Store::Nested;
use Any::Moose;
extends 'Jifty::CAS::Store';
has 'parts' => (is => 'rw');

=head1 NAME

Jifty::CAS::Store::Nested - A layered CAS store

=head1 DESCRIPTION

This is a layered backend for L<Jifty::CAS>, which provides a way to
combine multiple CAS backends.  Writes are passed through to every
layer, whereas reads stop on the first layer which contains the data.
This allows a fast in-memory store to be layered on top of a durable
file store, for instance.

Configuration requires providing two or more CAS classes:

    framework:
      CAS:
        Default:
          Class: Jifty::CAS::Store::Nested
          Parts:
            - Class: Jifty::CAS::Store::Memory
            - Class: Jifty::CAS::Store::LocalFile
              Path: %var/cas%

=head1 METHODS

=head2 BUILD

Constructs the sub-parts and stores them.

=cut

sub BUILD {
    my $self = shift;
    my @parts;
    for my $part (@{ $self->parts || [] }) {
        my %part = %{ $part };
        my $storeclass = delete $part{Class};
        Jifty::Util->require( $storeclass );
        push @parts, $storeclass->new(
            map {lc $_ => $part->{$_}} grep {$_ ne "Class"} keys %part
        );
    }
    $self->parts( \@parts );
}

=head2 _store DOMAIN NAME BLOB

Stores the BLOB (a L<Jifty::CAS::Blob>) in all parts, starting at the
bottom.  Returns the key on success or undef on failure.

=cut

sub _store {
    my ($self, $domain, $name, $blob) = @_;
    # Writes start on the bottom
    $_->_store($domain, $name, $blob) for reverse @{ $self->parts };
}

=head2 key DOMAIN NAME

Returns the most recent key for the given pair of C<DOMAIN> and
C<NAME>, or undef if none such exists.

=cut

sub key {
    my ($self, $domain, $name) = @_;
    # Reads start at the top
    my @missing;
    my $found;
    for my $part (@{$self->parts}) {
        if ($found = $part->key($domain, $name)) {
            if (@missing) {
                # If there were cache misses higher on the stack, write
                # the correct value back to them
                my $blob = $part->retrieve($domain, $found);
                $_->_store($domain, $name, $blob) for @missing;
            }
            return $found;
        }
        push @missing, $part;
    }
    return;
}

=head2 retrieve DOMAIN KEY

Returns a L<Jifty::CAS::Blob> for the given pair of C<DOMAIN> and
C<KEY>, or undef if none such exists.

=cut

sub retrieve {
    my ($self, $domain, $key) = @_;
    # We don't have a way of storing just the blob at a key location,
    # so we can't freshen the higher levels in this case.
    for my $part (@{$self->parts}) {
        my $found = $part->retrieve($domain, $key);
        return $found if $found;
    }
    return;
}

=head2 durable

If any of the parts are durable, the entire nested CAS backend is durable.

=cut

sub durable {
    my $self = shift;
    for my $part (@{$self->parts}) {
        return 1 if $part->durable;
    }
    return 0;
}

no Any::Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
