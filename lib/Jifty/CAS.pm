use strict;
use warnings;

package Jifty::CAS;
use base 'Jifty::CAS::Store';
use Plack::Request;
use Plack::Response;

=head1 NAME

Jifty::CAS - Jifty's Content-Addressable Storage facility

=head1 SYNOPSIS

  my $key = Jifty::CAS->publish('js' => 'all', $content,
                      { hash_with => $content, # default behaviour
                        content_type => 'application/x-javascript',
                      });

  $ie_key = Jifty::CAS->publish('js' => 'ie-only', $ie_content,
                      { hash_with => $ie_content,
                        content_type => 'application/x-javascript',
                      });

  $key = Jifty::CAS->key('js', 'ie-only');
  my $blob = Jifty::CAS->retrieve('js', $key);

=head1 DESCRIPTION

Provides an in-memory C<md5>-addressed content store.  Content is
stored under a "domain", and can be addressed using wither the "key",
which is an C<md5> sum, or the "name", which simply stores the most
recent key provided with that name.

=head1 BACKENDS

The default data store is an per-process, in-memory store.  A
L<memcached|Jifty::CAS::Store::Memcached> backed store is also available and
has the benefits of sharing the cache across all instances of a Jifty app using
Jifty::CAS.  The memcached store is limited to objects less than 1MB in size,
however.

=head1 METHODS

=head2 publish DOMAIN NAME CONTENT METADATA

Publishes the given C<CONTENT> at the address C<DOMAIN> and C<NAME>.
C<METADATA> is an arbitrary hash; see L<Jifty::CAS::Blob> for more.
Returns the key on success, or undef on failure.

=head2 key DOMAIN NAME

Returns the most recent key for the given pair of C<DOMAIN> and
C<NAME>, or undef if none such exists.

=head2 retrieve DOMAIN KEY

Returns a L<Jifty::CAS::Blob> for the given pair of C<DOMAIN> and
C<KEY>, or undef if none such exists.

=head2 serve_by_name DOMAIN NAME REQUESTED_KEY

Intelligently serves up the content of the object at NAME (B<not>
REQUESTED_KEY) in DOMAIN.  REQUESTED_KEY is currently used only to check if the
content at NAME equals the content requested.  If so, this method responds with
an HTTP 304 status, indicating the content hasn't changed.  This use case
assumes that content is served to clients from the CAS with the CAS key (an MD5
sum) as the filename or part of it.

The C<content_type> key in the requested object's metadata is expected to be
set and is used for the HTTP response.

This method is usually called from a dispatcher rule.  Returns the HTTP status
code set by this method (possibly for your use in the dispatcher).

=cut

sub serve_by_name {
    my ($class, $domain, $name, $incoming_key, $env) = @_;
    my $key = Jifty::CAS->key($domain, $name);

    return $class->_serve_404( $domain, $name, "Unable to lookup key." )
        if not defined $key;

    my $res = Plack::Response->new(200);
    my $req = Plack::Request->new($env);
    if ( $req->header('If-Modified-Since') and $incoming_key eq $key ) {
        Jifty->log->debug("Returning 304 for CAS cached $domain:$name ($key)");
        $res->status(304);
        return $res->finalize;
    }

    my $obj = Jifty::CAS->retrieve($domain, $key);

    return $class->_serve_404( $domain, $name, "Unable to retrieve blob." )
        if not defined $obj;

    $res->content_type($obj->metadata->{content_type});
    $res->header( 'Cache-Control' => 'max-age=31536000, public' );
    $res->header( 'Expires' => HTTP::Date::time2str( time() + 31536000 ) );
    $res->header( 'Content-Length' => length($obj->content) );
    $res->header(
      'Last-Modified' => HTTP::Date::time2str( $obj->metadata->{time} ) );

    Jifty->log->debug("Sending squished $domain:$name ($key) from CAS");
    $res->body($obj->content);

    return $res->finalize;
}

sub _serve_404 {
    my ($class, $domain, $name, $msg) = @_;
    $msg ||= '';
    Jifty->log->error("Returning 404 for CAS cached $domain:$name.  $msg");
    return Plack::Response->new(404)->finalize;
}

1;
