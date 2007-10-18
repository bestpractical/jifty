package Jifty::Plugin::OAuth;
use strict;
use warnings;

use base qw/Jifty::Plugin/;

our $VERSION = 0.01;

=head1 NAME

Jifty::Plugin::OAuth

=head1 DESCRIPTION

A OAuth web services API for your Jifty app.

=head1 WARNING

This plugin is not yet complete. DO NOT USE IT.

=head1 USAGE

Add the following to your site_config.yml

 framework:
   Plugins:
     - OAuth: {}

=cut

=head2 init

Provides defaults for the three URLs that OAuth needs:

=over 4

=item request_token: Request a RequestToken

/oauth/request_token

=item authorize: Authorize a RequestToken

/oauth/authorize

=item access_token: Exchange a RequestToken for an Accesstoken

/oauth/access_token

=cut

our %CONFIG;

sub init {
    my $self = shift;
    %CONFIG = (
        request_token => '/oauth/request_token',
        authorize     => '/oauth/authorize',
        access_token  => '/oauth/access_token',
        @_
    );
}

1;
