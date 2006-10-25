use strict;
use warnings;

package Jifty::Plugin::REST;
use base qw/Jifty::Plugin/;

our $VERSION = 0.01;

=head1 NAME

Jifty::Plugin::REST

=head1 DESCRIPTION

A RESTian web services API for your Jifty app.

=head1 USAGE

Add the following to your site_config.yml

 framework:
   Plugins:
     - REST: {}
 

=cut
1;
