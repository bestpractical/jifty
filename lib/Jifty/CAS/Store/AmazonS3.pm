use strict;
use warnings;

package Jifty::CAS::Store::AmazonS3;
use Any::Moose;
extends 'Jifty::CAS::Store';
has 's3' => ( is => 'rw', isa => 'Net::Amazon::S3');
has 'accesskey' => ( is => 'rw' );
has 'secret' => ( is => 'rw' );
has 'bucketprefix' => ( is => 'rw' );
has 'known_good' => ( is => 'rw' );

use Net::Amazon::S3;

=head1 NAME

Jifty::CAS::Store::AmazonS3 - An S3 backend for Jifty's CAS

=head1 SYNOPSIS


=head1 DESCRIPTION

This is an S3 backend for L<Jifty::CAS>.  For more information about
Jifty's CAS, see L<Jifty::CAS/DESCRIPTION>.

=cut

=head1 METHODS

=cut

sub BUILD {
    my $self = shift;
    $self->s3( Net::Amazon::S3->new(
        {
            aws_access_key_id     => $self->accesskey,
            aws_secret_access_key => $self->secret,
            retry                 => 1,
        }
    ) );

    $self->known_good({});
    my $response = $self->s3->buckets or die "Getting buckets";
    for my $bucket ( @{ $response->{buckets} }) {
        next unless index($bucket->bucket, $self->bucketprefix) == 0;
        $self->known_good->{$bucket->bucket} = $bucket;
    }
}

sub get_bucket {
    my $self = shift;
    my $domain = shift;
    return $self->known_good->{$domain} if $self->known_good->{$domain};

    my $bucket = $self->s3->add_bucket( {
        bucket => $self->bucketprefix . $domain,
        acl_short => "public-read",
    }) or die "Adding bucket for $domain";
    return $self->known_good->{$domain} = $bucket;
}

=head2 _store DOMAIN NAME BLOB

Stores the BLOB (a L<Jifty::CAS::Blob>) on S3.  Returns the key on
success or undef on failure.

=cut

sub _store {
    my ($self, $domain, $name, $blob) = @_;
    my $bucket = $self->get_bucket($domain);
    $bucket->add_key( $blob->key, $blob->content, $blob->metadata )
        or die "Adding key for ".$blob->key." for $name";
    $bucket->set_acl({acl_short => "public-read", key => $blob->key } );
    $bucket->copy_key(
        $name,
        "/" . $bucket->bucket . "/" . $blob->key,
    ) or die "Copying key for $name";
    $bucket->set_acl({acl_short => "public-read", key => $blob->key } );
    return $blob->key;
}

=head2 key DOMAIN NAME

Returns the most recent key for the given pair of C<DOMAIN> and
C<NAME>, or undef if none such exists.

=cut

sub key {
    my ($self, $domain, $name) = @_;
    my $bucket = $self->get_bucket($domain);
    my $data = $bucket->head_key($name) or die "Getting HEAD of $name";
    return $data->{etag};
}

=head2 retrieve DOMAIN KEY

Returns a L<Jifty::CAS::Blob> for the given pair of C<DOMAIN> and
C<KEY>, or undef if none such exists.

=cut

sub retrieve {
    my ($self, $domain, $key) = @_;
    my $bucket = $self->get_bucket($domain);
    my $data = $bucket->get_key($key);
    return unless $data;
    my $blob = Jifty::CAS::Blob->new();
    $blob->content( $data->{value} );
    $blob->key( $data->{etag} );
    $blob->metadata( { $data->{meta}, content_type => $data->{content_type} });
    return $blob;
}

sub uri {
    my $self = shift;
    my ($domain, $name) = @_;
    return "http://s3.amazonaws.com/" . $self->bucketprefix . $domain . "/" . $self->key($domain, $name);
}

sub serve {
    my ($self, $domain, $arg, $env) = @_;

    my $res = Plack::Response->new(302);
    $res->header( Location => "http://s3.amazonaws.com/" . $self->bucketprefix . "$domain/$arg" );
    return $res->finalize;
}

no Any::Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
