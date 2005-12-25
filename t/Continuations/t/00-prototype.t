#!/usr/bin/perl

use warnings;
use strict;

=head1 DESCRIPTION

This is a template for your own tests. Copy it and modify it.

=cut

BEGIN { -d 't/Continuations' &&  chdir 't/Continuations'; require 't/utils.pl'; };

use Test::More tests => 2;

use_ok('Jifty');
Jifty->new(  );


ok(1, "Loaded the test script");
1;

