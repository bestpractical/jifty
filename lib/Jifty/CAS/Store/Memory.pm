use strict;
use warnings;

package Jifty::CAS::Store::Memory;
use Any::Moose;
extends 'Jifty::CAS::Store';

=head1 NAME

Jifty::CAS::Store::Memory - An single-process in-memory CAS store

=head1 DESCRIPTION

This is the default backend store for L<Jifty::CAS>.  For more
information, see L<Jifty::CAS/DESCRIPTION>.

=cut

use Jifty::CAS::Blob;

my %CONTAINER;

=head2 _store DOMAIN NAME BLOB

Stores the BLOB (a L<Jifty::CAS::Blob>) in the backend.  Returns the
key.  Don't use this directly, use C<publish> instead.

=cut

sub _store {
    my ($self, $domain, $name, $blob) = @_;
    my $db  = $CONTAINER{$domain} ||= {};
    my $key = $blob->key;
    $db->{DB}{$key} = $blob;
    $db->{KEYS}{$name} = $key;
    return $key;
}

=head2 key DOMAIN NAME

Returns the most recent key for the given pair of C<DOMAIN> and
C<NAME>, or undef if none such exists.

=cut

sub key {
    my ($self, $domain, $name) = @_;
    return $CONTAINER{$domain}{KEYS}{$name};
}

=head2 retrieve DOMAIN KEY

Returns a L<Jifty::CAS::Blob> for the given pair of C<DOMAIN> and
C<KEY>, or undef if none such exists.

=cut

sub retrieve {
    my ($self, $domain, $key) = @_;
    return $CONTAINER{$domain}{DB}{$key};
}

no Any::Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
