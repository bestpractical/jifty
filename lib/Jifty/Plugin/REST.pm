use strict;
use warnings;

package Jifty::Plugin::REST;
use base qw/Jifty::Plugin/;

our $VERSION = '1.01';

=head1 NAME

Jifty::Plugin::REST - Add REST web services to your app

=head1 DESCRIPTION

A RESTian web services API for your Jifty app.

=head1 USAGE

Add the following to your site_config.yml

 framework:
   Plugins:
     - REST: {}

See the URL /=/help in your Jifty app for more information about
how to access the RESTian resources.

=cut

1;
