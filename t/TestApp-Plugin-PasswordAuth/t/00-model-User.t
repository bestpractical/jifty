#!/usr/bin/env perl
use warnings;
use strict;

=head1 DESCRIPTION

A basic test harness for the User model.

=cut

use Jifty::Test::Dist tests => 24;

# force to use English handle to compare strings successfully
Jifty::I18N->get_language_handle('en');

# Make sure we can load the model
use_ok('TestApp::Plugin::PasswordAuth::Model::User');

# Grab a system user
my $system_user = TestApp::Plugin::PasswordAuth::CurrentUser->superuser;
ok($system_user, "Found a system user");

# Try testing a create
my $o = TestApp::Plugin::PasswordAuth::Model::User->new(current_user => $system_user);
my ($id) = $o->create( name => 'jesse',
                       email => 'jrv',
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

can_ok($o, 'mygroup');
is ($o->mygroup, 'user', 'Default user is in group user');


my $p = TestApp::Plugin::PasswordAuth::Model::User->new(current_user => $system_user);
 ($id) = $p->create( name => 'jesse2',
                       email => 'jrv2',
                       color => 'blue',
                       swallow_type => 'african',
                       password => 'secret');
ok(!$id, "Users can't be created with the wrong favorite color");

my $q = TestApp::Plugin::PasswordAuth::Model::User->new(current_user => $system_user);
($id) = $p->create( name => 'jesse2',
                       email => 'jrv2',
                       color => 'gray',
                       swallow_type => 'european',
                       password => 'secret');
ok(!$id, "Users can't be created if they don't know african swallow_types are faster");

my $r = TestApp::Plugin::PasswordAuth::Model::User->new(current_user => $system_user);
 ($id) = $r->create( name => 'jesse2',
                       email => 'jrv2',
                       color => 'grey',
                       swallow_type => 'african',
                       password => 'secret');
ok($id, "Created with grey");

my ($res, $msg) = $r->set_password('foo');
TODO: {
local $TODO = 'Validators are applied too late - [rt.cpan.org #63750]';
ok(!$res, 'unable to set password shorter than 6');
like($msg||'', qr/at least six/);
ok($r->password_is('secret'), 'password not changed');
};

($id, $msg) = $r->create( name => 'jesse3',
                          email => 'jrv2@orz',
                          color => 'gray',
                          password => '',
                          swallow_type => 'african' );

ok(!$id, "Can't create without password");
like($msg, qr/at least six/);

($id, $msg) = $r->create( name => 'jesse3',
                          email => 'jrv2@orz',
                          color => 'gray',
                          password => 'short',
                          swallow_type => 'african' );

ok(!$id, "Can't create with a short password");
like($msg, qr/at least six/);

