#!/usr/bin/env perl -w
use strict;
use Test::More tests => 2;

BEGIN {
    #### XXX: I know this is foolish but right now Jifty on Win32 fails to 
    #### unlink used test databases and the following tests fail saying
    #### 'error creating a table... table already exists'. So, remove the
    #### remnant first. And we should do it before none of the Jifty is there.

    my $testdb = 'jiftyapptest';
    if (-e $testdb) {
        unlink $testdb or die $!;
    }
}

use_ok('Jifty::Everything');
use_ok('Jifty::Test');
