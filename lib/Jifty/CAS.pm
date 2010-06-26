use strict;
use warnings;

package Jifty::CAS;
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

The default data store is a per-process, in-memory store via
L<Jifty::CAS::Store::Memory>.  L<Jifty::CAS::Store::Memcached> is also
available, and has the benefits of sharing the cache across all
instances of a Jifty app using L<Jifty::CAS>.  The memcached store is
limited to objects less than 1MB in size, however.

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

=head2 uri DOMAIN NAME

Returns a URL where the given C<DOMAIN> and C<NAME> can be accessed.

=head2 serve DOMAIN ARGUMENT ENV

Serves a plack request in C<ENV>, given a C<DOMAIN> and an C<ARGUMENT>,
which may wither be a key or a name.  This method is usually only called
by L</wrap>, which calls it as appropriate for all requests under
C</__jifty/cas/>.

=head2 backend [DOMAIN]

Returns the L<Jifty::CAS::Store> which backs the given C<DOMAIN>.  If
C<DOMAIN> is not specified, returns the default backing store.

=head2 config

Returns the CAS configuration, as specified in the framework's
configuration.

=head2 setup

Configures the CAS for use.

=head2 wrap APP

Given a PSGI application, wraps it to handle C</__jifty/cas/> requests
by calling the appropriate L</serve> method.

=cut

sub config {
    my $class = shift;
    my $config = Jifty->config->framework('CAS');
    if (Jifty->config->framework('ConfigFileVersion') < 6) {
        $config = {
            Default => {
                Class => $config->{'BaseClass'},
                %{ $config->{'Memcached'} || {} },
            }
        };
    }
    $config->{Default}{Class} ||= "Jifty::CAS::Store::Memory";
    $config->{Domains} ||= {};
    return $config;
}

my %BACKENDS;
my $DEFAULT_BACKEND;
sub setup {
    my $class = shift;
    my $config = $class->config;

    my %default = %{$config->{Default}};
    my $defaultclass = delete $default{Class};
    Jifty::Util->require( $defaultclass );
    $DEFAULT_BACKEND = $defaultclass->new(
        map {lc $_ => $config->{Default}{$_}} keys %default
    );

    for my $domain (keys %{$config->{Domains}}) {
        my %domain = %{ $config->{Domains}{$domain} };
        my $storeclass = delete $domain{Class};
        Jifty::Util->require( $storeclass );
        $BACKENDS{$domain} = $storeclass->new(
            map {lc $_ => $config->{Domains}{$domain}{$_}} keys %domain
        );
    }
}

sub wrap {
    my ($class, $app) = @_;

    sub {
        my $env = shift;
        if (my ($domain, $arg) = $env->{PATH_INFO} =~ m{/__jifty/cas/(.*?)/(.*?)(?:\.|$)}) {
            return $class->serve($domain,$arg,$env);
        }
        else {
            return $app->($env);
        }
    };
}

sub backend {
    my $class = shift;
    my ($domain) = @_;
    return $DEFAULT_BACKEND unless @_;
    return $BACKENDS{$domain} || $DEFAULT_BACKEND;
}

sub publish {
    my $class = shift;
    my ($domain) = @_;
    ($BACKENDS{$domain} || $DEFAULT_BACKEND)->publish(@_);
}

sub key {
    my $class = shift;
    my ($domain) = @_;
    ($BACKENDS{$domain} || $DEFAULT_BACKEND)->key(@_);
}

sub retrieve {
    my $class = shift;
    my ($domain) = @_;
    ($BACKENDS{$domain} || $DEFAULT_BACKEND)->retrieve(@_);
}

sub uri {
    my $class = shift;
    my ($domain) = @_;
    ($BACKENDS{$domain} || $DEFAULT_BACKEND)->uri(@_);
}

sub serve {
    my $class = shift;
    my ($domain) = @_;
    ($BACKENDS{$domain} || $DEFAULT_BACKEND)->serve(@_);
}

1;
