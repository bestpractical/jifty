#!/usr/bin/env perl

use warnings;
use strict;

=head1 DESCRIPTION

Try out and make sure the the Create record action extends nicely.

=cut

use Jifty::Test::Dist tests => 5;

Jifty::Test->web;

my $action = Jifty->web->new_action(
    class     => 'NewSomething',
    arguments => {
        direction => 'forward',
        test3     => 'Prefect',
    },
);

is_deeply(
    [ sort $action->argument_names ], 
    [ 'direction', 'test3' ],
    'action has arguments');

$action->run;

ok($action->record->id, 'create a record');
is($action->record->test3, 'Prefect', 'changed to Prefect');

$action = Jifty->web->new_action(
    class     => 'NewSomething',
    arguments => {
        direction => 'reverse',
        test3     => 'Beeblebrox',
    },
);

$action->run;

ok($action->record->id, 'create a record again');
is($action->record->test3, 'xorbelbeeB', 'ends with Beeblebrox backwards');

