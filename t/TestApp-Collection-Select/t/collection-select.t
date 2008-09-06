#!/usr/bin/env perl
use warnings;
use strict;

use Jifty::Test::Dist tests => 15;
use Jifty::Test::WWW::Mechanize;

# Make sure we can load the models
use_ok('TestApp::Model::Author');
use_ok('TestApp::Model::Book');

# Grab a system user
my $system_user = TestApp::CurrentUser->superuser;
ok($system_user, "Found a system user");

# Create an author
my $o = TestApp::Model::Author->new(current_user => $system_user);
my ($id) = $o->create( name => 'Author One' );
ok($id, "Author create returned success");
ok($o->id, "New Author has valid id set");
is($o->id, $id, "Create returned the right id");

# And another
$o->create( name => 'Author Two' );
ok($o->id, "Author create returned another value");
isnt($o->id, $id, "And it is different from the previous one");

# Check we really have 2 author records created
my $collection =  TestApp::Model::AuthorCollection->new(current_user => $system_user);
$collection->unlimit;
is($collection->count, 2, "Finds two records");

# start a server
my $server = Jifty::Test->make_server;
ok($server, 'got a server');

my $url = $server->started_ok;

my $mech = Jifty::Test::WWW::Mechanize->new;

$mech->get_ok($url . '/__jifty/admin/model/Book', 'try getting /__jifty/admin/model/Book');

my $mon = $mech->moniker_for('TestApp::Action::CreateBook');
ok($mon, 'grab the form moniker');

ok($mech->action_field_value($mon, 'author'), 'check for author field');

ok($mech->select("J:A:F-author-$mon", $id), 'select 1st author');
