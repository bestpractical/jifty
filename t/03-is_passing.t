#!/usr/bin/env perl -w

use strict;

use Jifty::Test tests => 4;

ok( Jifty::Test->is_passing, 'is_passing, with no tests yet run' );
ok( Jifty::Test->is_passing, '            with tests run' );
ok( !Jifty::Test->is_done );

my $tb = Jifty::Test->builder;
$tb->current_test(8);
die "is_passing failed" if Jifty::Test->is_passing;

$tb->current_test(3);
pass;
die "is_passing failed" unless Jifty::Test->is_passing;
die "is_done failed" unless Jifty::Test->is_done;

