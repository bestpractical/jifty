#!/usr/bin/env perl

use strict;
use warnings;

use Shell::Command;

use Jifty::Test 'no_plan';

{
    my $tmpfile = "t/foo";
    is( Jifty::Test->test_file( $tmpfile ), $tmpfile );
    touch( $tmpfile );

    ok -e $tmpfile;
    Jifty::Test->_ending;
    ok !-e $tmpfile;
}


{
    my @tmpfiles = ("t/foo", "t/bar");
    is( Jifty::Test->test_file( $_ ), $_ ) for @tmpfiles;
    touch( $_ ) for @tmpfiles;

    ok -e $_ for @tmpfiles;
    Jifty::Test->_ending;
    ok !-e $_ for @tmpfiles;
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
