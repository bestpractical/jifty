#!/usr/bin/env perl
use warnings;
use strict;

=head1 DESCRIPTION

A basic test harness for the User model.

=cut
use lib 't/lib';
use Jifty::SubTest;

use Jifty::Test tests => 15;

# Make sure we can load the model
use_ok('TestApp::Plugin::PasswordAuth::Model::User');

# Grab a system user
my $system_user = TestApp::Plugin::PasswordAuth::CurrentUser->superuser;
ok($system_user, "Found a system user");

# Try testing a create
my $o = TestApp::Plugin::PasswordAuth::Model::User->new(current_user => $system_user);
my ($id) = $o->create( name => 'jesse',
                       username => 'jrv',
                       color => 'gray',
                       swallow_type => 'african',
                       password => 'secret');
ok($id, "User create returned success");
ok($o->id, "New User has valid id set");
is($o->id, $id, "Create returned the right id");

can_ok($o, 'name');

is($o->name, 'jesse');
ok(!$o->password, "Can't get the password");
can_ok($o,'set_password');
ok($o->password_is( 'secret'));
is($o->color, 'gray');
is ($o->swallow_type, 'african');


my $p = TestApp::Plugin::PasswordAuth::Model::User->new(current_user => $system_user);
 ($id) = $p->create( name => 'jesse2',
                       username => 'jrv2',
                       color => 'blue',
                       swallow_type => 'african',
                       password => 'secret');
ok(!$id, "Users can't be created with the wrong favorite color");

my $q = TestApp::Plugin::PasswordAuth::Model::User->new(current_user => $system_user);
($id) = $p->create( name => 'jesse2',
                       username => 'jrv2',
                       color => 'gray',
                       swallow_type => 'european',
                       password => 'secret');
ok(!$id, "Users can't be created if they don't know african swallow_types are faster");

my $r = TestApp::Plugin::PasswordAuth::Model::User->new(current_user => $system_user);
 ($id) = $r->create( name => 'jesse2',
                       username => 'jrv2',
                       color => 'grey',
                       swallow_type => 'african',
                       password => 'secret');
ok($id, "Created with grey");

