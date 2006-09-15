#!/usr/bin/env perl

use warnings;
use strict;

=head1 DESCRIPTION

This is a template for your own tests. Copy it and modify it.

=cut

use Jifty::Test tests => 2;

ok(1, "Loaded the test script");

my $server = Jifty::Test->make_server;
my $URL = $server->started_ok;


1;

