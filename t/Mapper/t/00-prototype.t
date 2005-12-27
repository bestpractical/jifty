#!/usr/bin/perl

use warnings;
use strict;

=head1 DESCRIPTION

This is a template for your own tests. Copy it and modify it.

=cut

BEGIN {chdir "t/Mapper"}
use lib '../../lib';
use Jifty::Test tests => 1;

ok(1, "Loaded the test script");
1;

