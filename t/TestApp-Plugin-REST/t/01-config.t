#!/usr/bin/env perl
use strict;
use warnings;

BEGIN {
    #### XXX: I know this is foolish but right now Jifty on Win32 fails to 
    #### unlink used test databases and the following tests fail saying
    #### 'error creating a table... table already exists'. So, remove the
    #### remnant first. And we should do it before none of the Jifty is there.

    my $testdb = 't/TestApp-Plugin-REST/testapp_plugin_resttest';
    if (-e $testdb) {
        unlink $testdb or die $!;
    }
}

use lib 'plugins/REST/lib';

#use Jifty::Test tests => 3;
use Jifty::Test tests => 1;

# todo: kevinr: these tests aren't right
#is(Jifty->config->framework('ApplicationClass'), 'jifty');
# is(Jifty->config->framework('LogConfig'), 't/btdttest.log4perl.conf');
# Port is overridden by testconfig
ok(Jifty->config->framework('Web')->{'Port'} >= 10000, "test nested config");


1;


