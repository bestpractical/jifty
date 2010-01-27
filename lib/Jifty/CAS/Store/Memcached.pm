use strict;
use warnings;

package Jifty::CAS::Store::Memcached;

use base 'Jifty::CAS::Store';

=head1 NAME

Jifty::CAS::Store::Memcached - A memcached backend for Jifty's
Content-Addressable Storage facility

=head1 SYNOPSIS

Add the following to your Jifty config.yml:

    framework:
      CAS:
        BaseClass: Jifty::CAS::Store::Memcached

=head1 DESCRIPTION

This is a memcached backend for L<Jifty::CAS>.  For more information, see
L<Jifty::CAS/DESCRIPTION>.

=cut

use Cache::Memcached;

our $MEMCACHED;


=head1 METHODS

=head2 memcached

Returns the L<Cache::Memcached> object for this class.

=cut

sub memcached {
    $MEMCACHED ||= Cache::Memcached->new( $_[0]->memcached_config );
}

=head2 _store DOMAIN NAME BLOB

Stores the BLOB (a L<Jifty::CAS::Blob>) in memcached.  Returns the key on
success or undef on failure.

=cut

sub _store {
    my ($class, $domain, $name, $blob) = @_;

    # Default to expiring in two weeks. XXX TODO this should be configurable
    my $key = $blob->key;
    my $success = $class->memcached->set("$domain:db:$key", $blob, 60*60*24*14);

    unless ($success) {
        my $err = "Failed to store content for key '$domain:db:$key' in memcached!";
        {
            use bytes;
            $err .= "  Content length is: " . length($blob->content) . " bytes.";
            $err .= "  Perhaps you need to increase memcached's max item size?";
        }
        Jifty->log->error($err);
        return;
    }

    $success = $class->memcached->set("$domain:keys:$name", $key, 60*60*24*14);

    unless ($success) {
        Jifty->log->error("Failed to store key '$domain:keys:$name' in memcached!");
        return;
    }

    return $key;
}

=head2 key DOMAIN NAME

Returns the most recent key for the given pair of C<DOMAIN> and
C<NAME>, or undef if none such exists.

=cut

sub key {
    my ($class, $domain, $name) = @_;
    return $class->memcached->get("$domain:keys:$name");
}

=head2 retrieve DOMAIN KEY

Returns a L<Jifty::CAS::Blob> for the given pair of C<DOMAIN> and
C<KEY>, or undef if none such exists.

=cut

sub retrieve {
    my ($class, $domain, $key) = @_;
    return $class->memcached->get("$domain:db:$key");
}

=head2 memcached_config

Returns a hashref containing arguments to pass to L<Cache::Memcached> during
construction. The defaults are like:

  {
      servers     => [ '127.0.0.1:11211' ],
      debug       => 0,
      namespace   => Jifty->config->framework('ApplicationName'),
      compress_threshold => 10240,
  }

To change these options, set them in your Jifty application config file under
C</framework/CAS/Memcached> like so:

    framework:
      CAS:
        BaseClass: Jifty::CAS::Store::Memcached
        Memcached:
            servers:
                - 10.0.0.2:11211
                - 10.0.0.3:11211
            compress_threshold: 5120

=cut

sub memcached_config {
    Jifty->config->framework('CAS')->{'Memcached'}
        || Jifty->config->defaults->{'framework'}{'CAS'}{'Memcached'}
}

1;
