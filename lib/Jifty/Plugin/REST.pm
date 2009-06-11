use strict;
use warnings;

package Jifty::Plugin::REST;
use base qw/Jifty::Plugin/;

our $VERSION = '1.12';

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

=head1 MISC

The REST interface calls a method named C<jifty_serialize_format> on
records and collections to downgrade them to simple data structures. By
default, this just lists the attributes specified with "column".  If you want
to include calculated values in your REST interface, you can do so by
overriding C<jifty_serialize_format>.

=cut

1;
