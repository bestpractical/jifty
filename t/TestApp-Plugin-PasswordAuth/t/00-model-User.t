#!/usr/bin/env perl
use warnings;
use strict;

=head1 DESCRIPTION

A basic test harness for the User model.

=cut

use Jifty::Test tests => 10;

# Make sure we can load the model
use_ok('TestApp::Plugin::PasswordAuth::Model::User');

# Grab a system user
my $system_user = TestApp::Plugin::PasswordAuth::CurrentUser->superuser;
ok($system_user, "Found a system user");

# Try testing a create
my $o = TestApp::Plugin::PasswordAuth::Model::User->new(current_user => $system_user);
my ($id) = $o->create( name => 'jesse',
                       username => 'jrv',
                       password => 'secret');
ok($id, "User create returned success");
ok($o->id, "New User has valid id set");
is($o->id, $id, "Create returned the right id");

can_ok($o, 'name');

is($o->name, 'jesse');
ok(!$o->password, "Can't get the password");
can_ok($o,'set_password');
is($o->__value('password'), 'secret');
