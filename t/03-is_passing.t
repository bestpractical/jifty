#!/usr/bin/env perl -w

use strict;

use File::Spec;

use Jifty::Test tests => 7;

my $tb = Jifty::Test->builder;

ok( Jifty::Test->is_passing, 'is_passing, with no tests yet run' );
ok( Jifty::Test->is_passing, '            with tests run' );
ok( !Jifty::Test->is_done );

ok( Jifty::Test->test_in_isolation( sub {
    fail();
    return !Jifty::Test->is_passing;
}));

ok( Jifty::Test->test_in_isolation( sub {
    $tb->current_test( $tb->expected_tests - 1 );
    fail();
    return Jifty::Test->is_done;
}));

ok( Jifty::Test->test_in_isolation( sub {
    $tb->current_test( $tb->expected_tests - 1 );
    pass() for 1..2;
    return !Jifty::Test->is_passing;
}));

ok( Jifty::Test->test_in_isolation( sub {
    $tb->current_test( $tb->expected_tests - 1 );
    pass();
    pass();
    return !Jifty::Test->is_done;
}));
