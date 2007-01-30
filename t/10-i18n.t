#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 2;

use DateTime;
use Jifty::Everything;

my $dt = DateTime->new( year => 1950, month => 1, day => 1 );

Jifty->new( no_handle => 1 );
my $lh = Jifty::I18N->new();



# the localization method used to break DateTime object stringification
is($dt,_($dt));

# Substitution needs to work, even in the default locale

my $base = "I have %1 concrete mixers";

is(_($base,2), "I have 2 concrete mixers");


