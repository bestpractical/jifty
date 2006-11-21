#!/usr/bin/perl -w

use Jifty::Test tests => 2;

use_ok 'Jifty::DateTime';

my $date = Jifty::DateTime->new_from_string("2006-05-03 01:23:45");
my $date_clone = $date->clone();
is $date, $date_clone;
