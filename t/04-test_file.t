#!/usr/bin/env perl

use strict;
use warnings;

use Shell::Command;

use Jifty::Test 'no_plan';

{
    my $tmpfile = "t/foo";
    is_deeply( [Jifty::Test->test_file( $tmpfile )], [$tmpfile] );
    touch( $tmpfile );

    is_deeply( [Jifty::Test->test_file( $tmpfile )], [$tmpfile] );
    touch( $tmpfile );

    ok -e $tmpfile;
    Jifty::Test->_ending;
    ok !-e $tmpfile;
}

{
    my $tmpfile = "t/bar";
    Jifty::Test->test_in_isolation( sub {
        fail();
        touch $tmpfile;
        Jifty::Test->_ending;
    });

    ok -e $tmpfile;
}
