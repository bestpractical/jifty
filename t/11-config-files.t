#!/usr/bin/env perl

use warnings;
use strict;

=head1 DESCRIPTION

Check that nested config files work as expected

=cut

use Jifty::Test tests => 1, no_handle => 1;

is(Jifty->config->framework('WhichConfigFile'), 'site', "We set the driver to what's in the site config file");


1;

