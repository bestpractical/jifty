#!/usr/bin/env perl
use warnings;
use strict;

=head1 DESCRIPTION

Test canonicalize on load_or_create

=cut

use lib 't/lib';
use Jifty::SubTest;

use Jifty::Test tests => 9;
use_ok('TestApp::Model::CanonTest');

# Grab a system use
my $system_user = TestApp::CurrentUser->superuser;
ok($system_user, "Found a system user");

# Try testing a create
my $o = TestApp::Model::CanonTest->new(current_user => $system_user);
my ($id) = $o->create( column_1 => 'foo#$bar' );
ok($id, "CanonTest create returned success");
ok($o->id, "New CanonTest has valid id set");
is($o->id, $id, "Create returned the right id");
is($o->column_1, 'foobar', "Created object has the right column_1");

# And another
$o->load_or_create( column_1 => 'foo()bar' );
ok($o->id, "CanonTest create returned value");
is($o->id, $id, "And it is same from the previous one");

# Searches in general
my $collection =  TestApp::Model::CanonTestCollection->new(current_user => $system_user);
$collection->unlimit;
is($collection->count, 1, "Finds one records");

