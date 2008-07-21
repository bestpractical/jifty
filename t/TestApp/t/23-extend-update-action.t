#!/usr/bin/env perl

use warnings;
use strict;

=head1 DESCRIPTION

Try out and make sure the the Update record action extends nicely.

=cut

use lib 't/lib';
use Jifty::SubTest;
use Jifty::Test tests => 4;

Jifty::Test->web;

my $model = TestApp::Model::Something->new;
$model->create( test3 => 'Dent' );
my $id = $model->id;

is($model->test3, 'Dent', 'starts as Dent');

my $action = Jifty->web->new_action(
    class     => 'ChangeSomething',
    record    => $model,
    arguments => {
        direction => 'forward',
        test3     => 'Prefect',
    },
);

is_deeply(
    [ sort $action->argument_names ], 
    [ 'direction', 'id', 'test3' ],
    'action has arguments');

$action->run;

$model->load($id);
is($model->test3, 'Prefect', 'changed to Prefect');

$action = Jifty->web->new_action(
    class     => 'ChangeSomething',
    record    => $model,
    arguments => {
        direction => 'reverse',
        test3     => 'Beeblebrox',
    },
);

$action->run;

$model->load($id);
is($model->test3, 'xorbelbeeB', 'ends with Beeblebrox backwards');

