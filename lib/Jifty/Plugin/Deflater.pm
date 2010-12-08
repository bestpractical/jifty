use strict;
use warnings;

package Jifty::Plugin::Deflater;
use base 'Jifty::Plugin';
use Plack::Builder;
use Plack::Util;

=head1 NAME

Jifty::Plugin::Deflater - Handles Accept-Encoding and compression

=head1 SYNOPSIS

# In your jifty config.yml under the framework section:

  Plugins:
    - Deflater: {}

# You should put defalter at the end of the plugins list

=head1 DESCRIPTION

This plugin provides Accept-Encoding handling.

=head1 METHODS

=head2 wrap APP

Wraps the provided Plack app with the deflation middleware.  You'll never need
to call this yourself.

=cut

sub wrap {
    my ($self, $app) = @_;

    builder {
        enable 'Deflater';
        enable sub { my $app = shift;
                     sub { my $env = shift;
                           my $res = $app->($env);
                           # skip streamy response
                           return $res unless ref($res) eq 'ARRAY' && $res->[2];
                           my $h = Plack::Util::headers($res->[1]);
                           my $type = $h->get('Content-Type')
                               or return $res;
                           delete $env->{HTTP_ACCEPT_ENCODING}
                               unless $type =~ m|application/x-javascript| || $type =~ m|^text/|;
                           $res }
                 };
        $app;
    };
}

1;
