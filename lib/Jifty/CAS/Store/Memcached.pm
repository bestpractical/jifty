use strict;
use warnings;

package Jifty::CAS::Store::Memcached;
use Any::Moose;
extends 'Jifty::CAS::Store';

use Cache::Memcached;

=head1 NAME

Jifty::CAS::Store::Memcached - A memcached backend for Jifty's
Content-Addressable Storage facility

=head1 SYNOPSIS

At the bare minimum, add the following to your Jifty config.yml:

    framework:
      CAS:
        BaseClass: 'Jifty::CAS::Store::Memcached'

The options available include:

    framework:
      CAS:
        BaseClass: 'Jifty::CAS::Store::Memcached'
        Memcached:
          # any options Cache::Memcached supports
          servers:
            - 10.0.0.2:11211
            - 10.0.0.3:11211
          compress_threshold: 5120

        # Turned on by default. Keeps CAS working when memcached fails by
        # falling back to the default in-process store. It probably should
        # be turned off in most cases (like so) after successful testing.
        MemcachedFallback: 0

=head1 DESCRIPTION

This is a memcached backend for L<Jifty::CAS>.  For more information about
Jifty's CAS, see L<Jifty::CAS/DESCRIPTION>.

=head1 METHODS

=head2 BUILD

Constructs the L</memcached> object for this object, based on the
specified C<servers>, C<debug>, C<namespace>, and C<compress_threshold>
arguments in the CAS configuration.

=cut

our $MEMCACHED;


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
    my ($self, $domain, $name, $blob) = @_;

    my $key = $blob->key;
    my $success = $self->memcached->set("$domain:db:$key", $blob);

    unless ($success) {
        my $err = "Failed to store content for key '$domain:db:$key' in memcached!";
        {
            use bytes;
            $err .= "  Content length is: " . length($blob->content) . " bytes.";
            $err .= "  Perhaps you need to increase memcached's max item size?";
        }
        Jifty->log->error($err);

        if ( $self->memcached_fallback ) {
            Jifty->log->error("Falling back to default, in-process memory store.  "
                             ."This is suboptimal and you should investigate the cause.");
            return $self->SUPER::_store($domain, $name, $blob);
        }
        else {
            # fail with undef
            return;
        }
    }

    $success = $self->memcached->set("$domain:keys:$name", $key);

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
    my ($self, $domain, $name) = @_;
    my $key = $self->memcached->get("$domain:keys:$name");
    return $key if defined $key;
    return $self->SUPER::key($domain, $name) if $self->memcached_fallback;
    return;
}

=head2 retrieve DOMAIN KEY

Returns a L<Jifty::CAS::Blob> for the given pair of C<DOMAIN> and
C<KEY>, or undef if none such exists.

=cut

sub retrieve {
    my ($self, $domain, $key) = @_;
    my $blob = $self->memcached->get("$domain:db:$key");
    return $blob if defined $blob;
    return $self->SUPER::retrieve($domain, $key) if $self->memcached_fallback;
    return;
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
        BaseClass: 'Jifty::CAS::Store::Memcached'
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

=head2 memcached_fallback

Returns a boolean (from the config file) indicating whether or not memcached
should fallback to the per-process, in-memory store.

=cut

sub memcached_fallback {
    Jifty->config->framework('CAS')->{'MemcachedFallback'} ? 1 : 0
}

no Any::Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
