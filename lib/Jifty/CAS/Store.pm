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

=head2 uri DOMAIN NAME

Returns a URL where the given C<DOMAIN> and C<NAME> can be accessed.

=cut

sub uri {
    my $self = shift;
    my ($domain, $name) = @_;
    return "/__jifty/cas/$domain/" . $self->key($domain, $name);
}

=head2 serve DOMAIN ARGUMENT ENV

Serves a plack request in C<ENV>, given a C<DOMAIN> and an C<ARGUMENT>,
which may wither be a key or a name.

This correctly uses the C<If-None-Match> and C<Etag> headers to send
HTTP 304 responses to unchanged content.  Additionally, the
C<content_type> key in the requested object's metadata is expected to be
set and is used for the HTTP response.  This method is usually only
called by L<JiftY::CAS/wrap>, which calls this method as appropriate for
requests under C</__jifty/cas/>.

=cut

sub serve {
    my ($self, $domain, $arg, $env) = @_;

    my $key;
    if ($arg =~ /^[a-f0-9]{32}$/) {
        $key = $arg;
    } else {
        $key = $self->key($domain, $arg);
        return $self->_serve_404( $domain, $arg, "Unable to lookup key." )
            if not defined $key;
    }

    my $req = Plack::Request->new($env);
    my $etag = $req->header('If-None-Match');
    if ( defined $etag and $etag eq qq["$key"] ) {
        Jifty->log->info("Returning 304 for CAS cached $domain:$key");
        return Plack::Response->new(304)->finalize;
    }

    my $obj = Jifty::CAS->retrieve($domain, $key);
    return $self->_serve_404( $domain, $key, "Unable to retrieve blob." )
        if not defined $obj;

    my $res = Plack::Response->new(200);
    my $length = length($obj->content);
    $res->content_type($obj->metadata->{content_type});
    $res->header( 'Cache-Control' => 'max-age=31536000, public' );
    $res->header( 'Expires' => HTTP::Date::time2str( time() + 31536000 ) );
    $res->header( 'ETag' => '"'.$obj->key.'"' );
    $res->header( 'Content-Length' => $length );
    $res->header(
      'Last-Modified' => HTTP::Date::time2str( $obj->metadata->{time} ) );

    Jifty->log->info("Sending $domain:$key from CAS ($length bytes)");
    $res->body($obj->content);

    return $res->finalize;
}

sub _serve_404 {
    my ($self, $domain, $name, $msg) = @_;
    $msg ||= '';
    Jifty->log->error("Returning 404 for CAS cached $domain:$name.  $msg");
    return Plack::Response->new(404)->finalize;
}

=head2 durable

Returns true if the backing store is durable -- that is, if there is a
guarantee that data placed there will be accessible from all proccesses at
all later times.

=cut

sub durable { 0 }

no Any::Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
