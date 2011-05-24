use strict;
use warnings;

package Jifty::CAS::Store::Memcached;
use Any::Moose;
extends 'Jifty::CAS::Store';
has 'servers'            => (is => 'rw');
has 'debug'              => (is => 'rw');
has 'namespace'          => (is => 'rw');
has 'compress_threshold' => (is => 'rw');
has 'memcached'          => (is => 'rw');

use Cache::Memcached;

=head1 NAME

Jifty::CAS::Store::Memcached - A memcached backend for Jifty's CAS

=head1 SYNOPSIS

At the bare minimum, add the following to your Jifty config.yml:

    framework:
      CAS:
        Default:
          Class: 'Jifty::CAS::Store::Memcached'

The options available include:

    framework:
      CAS:
        Default:
          Class: 'Jifty::CAS::Store::Memcached'
          # any options Cache::Memcached supports
          Servers:
            - 10.0.0.2:11211
            - 10.0.0.3:11211
          Compress_Threshold: 5120

=head1 DESCRIPTION

This is a memcached backend for L<Jifty::CAS>.  For more information about
Jifty's CAS, see L<Jifty::CAS/DESCRIPTION>.

=head1 METHODS

=head2 BUILD

Constructs the L</memcached> object for this object, based on the
specified C<servers>, C<debug>, C<namespace>, and C<compress_threshold>
arguments in the CAS configuration.

=cut

sub BUILD {
    my $self = shift;
    $self->memcached(
        Cache::Memcached->new(
            servers => $self->servers || [ '127.0.0.1:11211' ],
            debug => $self->debug,
            namespace => $self->namespace || Jifty->config->framework('ApplicationName').":CAS:",
            compress_threshold => $self->compress_threshold || 10240,
        )
    );
}

=head2 memcached

Returns the L<Cache::Memcached> object for this class.

=cut

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

        # fail with undef
        return;
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
    return;
}

no Any::Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
