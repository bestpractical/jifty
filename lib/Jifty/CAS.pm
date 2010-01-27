use strict;
use warnings;

package Jifty::CAS;
use base 'Jifty::CAS::Store';

=head1 NAME

Jifty::CAS - Jifty's Content-Addressable Storage facility

=head1 SYNOPSIS

  my $key = Jifty::CAS->publish('js' => 'all', $content,
                      { hash_with => $content, # default behaviour
                        content_type => 'application/x-javascript',
                        deflate => 1
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
Returns the key.

=head2 key DOMAIN NAME

Returns the most recent key for the given pair of C<DOMAIN> and
C<NAME>, or undef if none such exists.

=head2 retrieve DOMAIN KEY

Returns a L<Jifty::CAS::Blob> for the given pair of C<DOMAIN> and
C<KEY>, or undef if none such exists.

=cut

1;
