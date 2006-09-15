#!/usr/bin/env perl

use warnings;
use strict;

=head1 DESCRIPTION

This is a template for your own tests. Copy it and modify it.

=cut

use Jifty::Test tests => 2;

use_ok('Jifty');

Jifty->new(no_handle => 1);

is(Jifty->config->framework('Database')->{'Driver'}, 'Pg', "We set the driver to what's in the site config file");


1;

