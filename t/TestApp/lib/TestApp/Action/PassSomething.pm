use strict;
use warnings;

package TestApp::Action::PassSomething;
use base qw/ Jifty::Action::Record::Do /;

use Test::More ();

use Jifty::Param::Schema;
use Jifty::Action schema {
    param 'test1';
};

sub record_class { 'TestApp::Model::Something' }

sub take_action {
    my $self = shift;

    Test::More::ok(1, 'taking action');
    Test::More::is($self->argument_value('test1'), 42,        'test1 is 42');
    Test::More::is($self->argument_value('test2'), 'Prefect', 'test2 is Prefect');

    Test::More::isa_ok($self->record, 'TestApp::Model::Something');
    Test::More::is($self->record->test3, 'Dent', 'test3 is Dent');
}

1
