use strict;
use warnings;

package Jifty::CAS::Store;

=head1 NAME

Jifty::CAS::Store - The default, per-process, in-memory store for Jifty's
Content-Addressable Storage facility

=head1 DESCRIPTION

This is the default backend store for L<Jifty::CAS>.  For more information, see
L<Jifty::CAS/DESCRIPTION>.

=cut

use Jifty::CAS::Blob;

my %CONTAINER;

=head2 publish DOMAIN NAME CONTENT METADATA

Publishes the given C<CONTENT> at the address C<DOMAIN> and C<NAME>.
C<METADATA> is an arbitrary hash; see L<Jifty::CAS::Blob> for more.
Returns the key.

=cut

sub publish {
    my ($class, $domain, $name, $content, $opt) = @_;
    $opt ||= {};

    my $blob = Jifty::CAS::Blob->new(
        {   content  => $content,
            metadata => $opt,
        }
    );
    return $class->_store( $domain, $name, $blob );
}

=head2 _store DOMAIN NAME BLOB

Stores the BLOB (a L<Jifty::CAS::Blob>) in the backend.  Returns the key.  Don't use this directly, use C<publish> instead.

=cut

sub _store {
    my ($class, $domain, $name, $blob) = @_;
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
    my ($class, $domain, $name) = @_;
    return $CONTAINER{$domain}{KEYS}{$name};
}

=head2 retrieve DOMAIN KEY

Returns a L<Jifty::CAS::Blob> for the given pair of C<DOMAIN> and
C<KEY>, or undef if none such exists.

=cut

sub retrieve {
    my ($class, $domain, $key) = @_;
    return $CONTAINER{$domain}{DB}{$key};
}

1;
