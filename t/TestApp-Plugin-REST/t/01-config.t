#!/usr/bin/env perl
use strict;
use warnings;

#use Jifty::Test tests => 3;
use Jifty::Test tests => 1;

# todo: kevinr: these tests aren't right
#is(Jifty->config->framework('ApplicationClass'), 'jifty');
# is(Jifty->config->framework('LogConfig'), 't/btdttest.log4perl.conf');
# Port is overridden by testconfig
ok(Jifty->config->framework('Web')->{'Port'} >= 10000, "test nested config");


1;


