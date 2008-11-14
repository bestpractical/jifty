#!/usr/bin/env perl
use strict;
use warnings;

use Jifty::Test tests => 1;

ok(Jifty->config->framework('Web')->{'Port'} >= 10000, "test nested config");

1;


