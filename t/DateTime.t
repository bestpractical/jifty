#!/usr/bin/perl -w

use Jifty::Test tests => 3;

use_ok 'Jifty::DateTime';

my $date = Jifty::DateTime->new_from_string("2006-05-03 01:23:45");
my $date_clone = eval {
    Jifty::DateTime->new_from_string($date);
};
is $@, '', "new_from_string() can handle string overloaded objects";
is $date, $date_clone;
