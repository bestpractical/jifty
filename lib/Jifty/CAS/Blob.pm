package Jifty::CAS::Blob;
use strict;

use base 'Class::Accessor::Fast';
use Digest::MD5 'md5_hex';
use Compress::Zlib ();

=head1 NAME

Jifty::CAS::Blob - An object in Jifty's content-addressed store

=head1 SYNOPSIS

  my $blob = Jifty::CAS->retrieve('js', $key);
  my $content = $blob->content;
  my $meta = $blob->metadata;
  my $key = $blob->key;

=head1 DESCRIPTION

Objects in the content-addressed store can have arbitrary metadata
associated with them, in addition to storing their contents.

=head1 METHODS

=head2 new HASHREF

Takes a HASHREF, with possible keys L</content> and L</metadata>, and
creates a new object.  Possible special keys in the metadata include:

=over

=item hash_with

Provides the data to hash to generate the address.  If no C<hash_with>
is provided, the content itself is hashed.

=item deflate

If set to a true value, deflates the content using
L<Compress::Zlib/memGzip>, and stores that in L</content_deflated>.

=back

=head2 content

Returns the content of the blob.

=head2 content_deflated

If L</deflate> in the metadata was set, contains the deflated content.

=head2 metadata

Returns a hashref of metadata.

=head2 key

Retuens the key calculated for this content.

=cut

__PACKAGE__->mk_accessors(qw(content metadata key));

sub new {
    my $class = shift;
    my $args = shift;
    my $self  = $class->SUPER::new( {
        content => "",
        metadata => {},
        %$args,
    } );
    $self->key( md5_hex( $self->metadata->{hash_with} || $self->content ) );
    return $self;
}

sub content_deflated {
    my $self = shift;
    return unless $self->metadata->{deflate};

    $self->{content_deflated} = Compress::Zlib::memGzip( $self->content )
        unless exists $self->{content_deflated};

    return $self->{content_deflated};
}

1;
