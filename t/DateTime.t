#!/usr/bin/perl -w

use Jifty::Test tests => 8;

use_ok 'Jifty::DateTime';

my $date = Jifty::DateTime->new_from_string("2006-05-03 01:23:45");
my $date_clone = $date->clone();
is $date, $date_clone;

is $date->friendly_date, '2006-05-03';

$date = Jifty::DateTime->now;
is $date->friendly_date, 'today';

$date = Jifty::DateTime->now->subtract(days => 1);
is $date->friendly_date, 'yesterday';

$date = Jifty::DateTime->now->subtract(days => 2);
like $date->friendly_date, qr/^\d\d\d\d-\d\d-\d\d$/;

$date = Jifty::DateTime->now->add(days => 1);
is $date->friendly_date, 'tomorrow';

$date = Jifty::DateTime->now->add(days => 2);
like $date->friendly_date, qr/^\d\d\d\d-\d\d-\d\d$/;

