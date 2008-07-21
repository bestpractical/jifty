#!/usr/bin/env perl

use warnings;
use strict;

=head1 DESCRIPTION

Try out and make sure the the Do record action extends nicely.

=cut

use lib 't/lib';
use Jifty::SubTest;
use Jifty::Test tests => 5;

Jifty::Test->web;

my $model = TestApp::Model::Something->new;
$model->create( test3 => 'Dent' );

my $action = Jifty->web->new_action(
    class     => 'PassSomething',
    record    => $model,
    arguments => {
        test1 => 42,
        test2 => 'Prefect',
    },
);

$action->run;
