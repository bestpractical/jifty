#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 1;

use DateTime;
use Jifty::Everything;

my $dt = DateTime->new( year => 1950, month => 1, day => 1 );

Jifty->new( no_handle => 1 );
my $lh = Jifty::I18N->new();


# the localization method used to break DateTime object stringification
is($dt,_($dt));


