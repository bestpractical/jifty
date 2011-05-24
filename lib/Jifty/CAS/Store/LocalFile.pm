use strict;
use warnings;

package Jifty::CAS::Store::LocalFile;
use Any::Moose;
extends 'Jifty::CAS::Store';
has 'path' => ( is => 'rw');

use Storable qw(lock_store lock_retrieve);

=head1 NAME

Jifty::CAS::Store::LocalFile - A local file backend for Jifty's CAS

=head1 DESCRIPTION

This is a local file backend for L<Jifty::CAS>, which provides a
B<durable> backend, unlike L<Jifty::CAS::Store::Memory> and
L<Jifty::CAS::Store::Memcached>.  For more information about Jifty's
CAS, see L<Jifty::CAS/DESCRIPTION>.

Configuration requires providing a directory which is writable by the
web user:

    framework:
      CAS:
        Default:
          Class: 'Jifty::CAS::Store::LocalFile'
          Path: %var/cas%

=cut

=head1 METHODS

=head2 _store DOMAIN NAME BLOB

Stores the BLOB (a L<Jifty::CAS::Blob>) on disk.  Returns the key on
success or undef on failure.

=cut

sub _store {
    my ($self, $domain, $name, $blob) = @_;
    mkdir($self->path) unless -d $self->path;
    my $dir = $self->path . "/" . $domain;
    mkdir($dir) unless -d $dir;

    my $path = $dir . "/key-" . $blob->key;
    unless (-e $path) {
        lock_store($blob, $path)
            or warn("Write of blob failed: $!") and return;
    }

    # Update the symlink
    my $link = $dir . "/name-" . $name;
    my $tmp  = $dir . "/tmp-"  . $name;
    symlink( "key-".$blob->key, $tmp )
        or warn("Symlink failed: $!") and return;
    rename( $tmp, $link )
        or warn("Rename of symlink failed: $!") and return;

    return $blob->key;
}

=head2 key DOMAIN NAME

Returns the most recent key for the given pair of C<DOMAIN> and
C<NAME>, or undef if none such exists.

=cut

sub key {
    my ($self, $domain, $name) = @_;
    my $link = $self->path . "/" . $domain . "/name-" . $name;
    return unless -l $link;
    $link = readlink($link);
    $link =~ s/^key-//;
    return $link;
}

=head2 retrieve DOMAIN KEY

Returns a L<Jifty::CAS::Blob> for the given pair of C<DOMAIN> and
C<KEY>, or undef if none such exists.

=cut

sub retrieve {
    my ($self, $domain, $key) = @_;
    my $data = $self->path . "/" . $domain . "/key-" . $key;
    return unless -r $data;

    return lock_retrieve($data);
}

=head2 durable

Since presumably the files on disk will not simply vanish, the local
file store is durable.

=cut

sub durable { 1 }

no Any::Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
