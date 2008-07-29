#!/usr/bin/env perl

use warnings;
use strict;

=head1 DESCRIPTION

This is a template for your own tests. Copy it and modify it.

=cut

use Jifty::Test::Dist tests => 3;

ok(1, "Loaded the test script");

my $app_instance = Jifty->app_instance_id;
ok(Jifty->app_instance_id, "We have an instance id ". Jifty->app_instance_id);
is($app_instance, Jifty->app_instance_id, "We have an instance id ". Jifty->app_instance_id);


1;

