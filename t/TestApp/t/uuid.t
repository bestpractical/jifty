#!/usr/bin/env perl
use warnings;
use strict;

=head1 DESCRIPTION

A basic test harness for the User model.

=cut

use lib 't/lib';
use Jifty::SubTest;

use Jifty::Test tests => 12;
# Make sure we can load the model
use_ok('TestApp::Model::User');

# Grab a system use
my $system_user = TestApp::CurrentUser->superuser;
ok($system_user, "Found a system user");

# Try testing a create
my $o = TestApp::Model::User->new(current_user => $system_user);
my ($id) = $o->create( name => $$, email => $$, password => $$ );
ok($id, "User create returned success");
ok($o->id, "New User has valid id set");
is($o->id, $id, "Create returned the right id");
is($o->name, $$, "Created object has the right name");
ok($o->__uuid, "We got a UUID");



# And another
my $p = TestApp::Model::User->new(current_user => $system_user);
$p->create( name => $$, email => $$, password => $$ );
ok($p->id, "User create returned another value");
isnt($p->__uuid, $o->__uuid, "And it is different from the previous one");

my $generated_uuid = Jifty::Util->generate_uuid;
my $q = TestApp::Model::User->new(current_user => $system_user);
$q->create( name => $$, email => $$, password => $$, __uuid =>$generated_uuid);
ok($q->id, "User create returned another value");
is($q->__uuid, $generated_uuid);
isnt($q->__uuid, $o->__uuid, "And it is different from the previous one");


