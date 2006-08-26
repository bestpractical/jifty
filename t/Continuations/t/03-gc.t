#!/usr/bin/env perl

use warnings;
use strict;

BEGIN {
    #### XXX: I know this is foolish but right now Jifty on Win32 fails to 
    #### unlink used test databases and the following tests fail saying
    #### 'error creating a table... table already exists'. So, remove the
    #### remnant first. And we should do it before none of the Jifty is there.

    my $testdb = 't/Continuations/continuationstest';
    if (-e $testdb) {
        unlink $testdb or die $!;
    }
}

# {{{ Setup
use lib 't/lib';
use Jifty::SubTest;

use Jifty::Test skip_all => "test file not done yet";

#### garbage collection
#  for now, an "on request, sweep all continuations older than the last 50"?
# continuations need a timestamp. so we can tell what's out of date.
