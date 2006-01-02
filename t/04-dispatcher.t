#!/usr/bin/perl

use warnings;
use strict;

use Test::More qw/no_plan/;
use_ok('Jifty::Dispatcher');
use_ok('Jifty');
ok(Jifty->new(no_handle => 1));
my $d = Jifty::Dispatcher->new();

can_ok($d,'on');


ok(Jifty::Dispatcher::on( condition => sub { 1 }, action => sub {2}, priority => 25));
my @entries = Jifty->dispatcher->entries();
is (scalar @entries, 1);
is (&{$entries[0]->{condition}},1);
is (&{$entries[0]->{action}},2);

ok(Jifty::Dispatcher::on( condition => sub { 1 }, action => sub {2}, priority => 25));
@entries = Jifty->dispatcher->entries();
is (scalar @entries, 2);

eval 'package Jifty::Dispatcher;  on url "foo", run { qq{xxx} }; ';

ok(!$@, $@);
@entries = Jifty->dispatcher->entries();

is (scalar @entries, 3);



