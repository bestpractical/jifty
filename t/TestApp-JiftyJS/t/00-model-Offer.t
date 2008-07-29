#!/usr/bin/env perl
use warnings;
use strict;

=head1 DESCRIPTION

A basic test harness for the Offer model.

=cut

use Jifty::Test::Dist tests => 11;

# Make sure we can load the model
use_ok('TestApp::JiftyJS::Model::Offer');

# Grab a system user
my $system_user = TestApp::JiftyJS::CurrentUser->superuser;
ok($system_user, "Found a system user");

# Try testing a create
my $o = TestApp::JiftyJS::Model::Offer->new(current_user => $system_user);
my ($id) = $o->create();
ok($id, "Offer create returned success");
ok($o->id, "New Offer has valid id set");
is($o->id, $id, "Create returned the right id");

# And another
$o->create();
ok($o->id, "Offer create returned another value");
isnt($o->id, $id, "And it is different from the previous one");

# Searches in general
my $collection =  TestApp::JiftyJS::Model::OfferCollection->new(current_user => $system_user);
$collection->unlimit;
is($collection->count, 2, "Finds two records");

# Searches in specific
$collection->limit(column => 'id', value => $o->id);
is($collection->count, 1, "Finds one record with specific id");

# Delete one of them
$o->delete;
$collection->redo_search;
is($collection->count, 0, "Deleted row is gone");

# And the other one is still there
$collection->unlimit;
is($collection->count, 1, "Still one left");

