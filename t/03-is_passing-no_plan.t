#!/usr/bin/env perl -w

use strict;

# This is specificly testing with no_plan.
use Jifty::Test 'no_plan';

ok( !Jifty::Test->is_done );
ok( Jifty::Test->is_done );
ok( Jifty::Test->is_passing );

ok( !Jifty::Test->test_in_isolation( sub {
    fail();
    return Jifty::Test->is_passing;
}));
