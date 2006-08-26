#!/usr/bin/env perl

use warnings;
use strict;

=head1 DESCRIPTION

This is a template for your own tests. Copy it and modify it.

=cut

BEGIN {
    #### XXX: I know this is foolish but right now Jifty on Win32 fails to 
    #### unlink used test databases and the following tests fail saying
    #### 'error creating a table... table already exists'. So, remove the
    #### remnant first. And we should do it before none of the Jifty is there.

    my $testdb = 't/TestApp/testapptest';
    if (-e $testdb) {
        unlink $testdb or die $!;
    }
}

use lib 't/lib';
use Jifty::SubTest;

use Jifty::Test tests => 1;

ok(1, "Loaded the test script");
1;

