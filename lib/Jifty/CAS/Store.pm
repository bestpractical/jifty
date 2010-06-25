use strict;
use warnings;

package Jifty::CAS::Store;
use Any::Moose;

=head1 NAME

Jifty::CAS::Store - Abstract class for Jifty's Content-Addressed Storage

=head1 DESCRIPTION

This is the abstract base class for a backend store for L<Jifty::CAS>.
For more information, see L<Jifty::CAS/DESCRIPTION>.

=cut

use Jifty::CAS::Blob;

=head2 publish DOMAIN NAME CONTENT METADATA

Publishes the given C<CONTENT> at the address C<DOMAIN> and C<NAME>.
C<METADATA> is an arbitrary hash; see L<Jifty::CAS::Blob> for more.
Returns the key.

=cut

sub publish {
    my ($self, $domain, $name, $content, $opt) = @_;
    $opt ||= {};

    my $blob = Jifty::CAS::Blob->new(
        {   content  => $content,
            metadata => $opt,
        }
    );
    return $self->_store( $domain, $name, $blob );
}

=head2 _store DOMAIN NAME BLOB

Stores the BLOB (a L<Jifty::CAS::Blob>) in the backend.  Returns the
key.  Subclasses should override this, but it should not be called
directly -- use L</publish> instead.

=cut

sub _store {
    die "This is an abstract base class; use one of the provided subclasses instead\n";
}

=head2 key DOMAIN NAME

Returns the most recent key for the given pair of C<DOMAIN> and C<NAME>,
or undef if none such exists.  Subclasses should override this.

=cut

sub key {
    die "This is an abstract base class; use one of the provided subclasses instead\n";
}

=head2 retrieve DOMAIN KEY

Returns a L<Jifty::CAS::Blob> for the given pair of C<DOMAIN> and
C<KEY>, or undef if none such exists.  Subclasses should override this.

=cut

sub retrieve {
    die "This is an abstract base class; use one of the provided subclasses instead\n";
}

no Any::Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
