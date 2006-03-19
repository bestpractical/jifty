#!/usr/bin/perl 

use warnings;
use strict;

use Test::More qw/no_plan/;
use_ok('Jifty');
Jifty->new( no_handle =>1 );

use_ok('Jifty::Web::Session');

my $s = Jifty::Web::Session->new();

isa_ok($s,'Jifty::Web::Session');

$s->load();
is($s->get('foo'), undef);
$s->set( foo => 'bar');
is($s->get('foo'), 'bar');

1;
