#!/usr/bin/env perl

use warnings;
use strict;

=head1 DESCRIPTION

This is a template for your own tests. Copy it and modify it.

=cut

use lib 'plugins/REST/lib';

use lib 't/lib';
use Jifty::SubTest;

use Jifty::Test tests => 27;
use Jifty::Test::WWW::Mechanize;

my $server  = Jifty::Test->make_server;

isa_ok($server, 'Jifty::Server');

my $URL     = $server->started_ok;
my $mech    = Jifty::Test::WWW::Mechanize->new();

ok(1, "Loaded the test script");

my $u1 = TestApp::Plugin::REST::Model::User->new(
    current_user => TestApp::Plugin::REST::CurrentUser->superuser );
$u1->create( name => 'test', email => 'test@example.com' );
ok( $u1->id );

# on GET    '/=/model'       => \&list_models;

$mech->get_ok("$URL/=/model.yml", "Got model list");
my $list = Jifty::YAML::Load($mech->content);
is(scalar @$list, 1, "Got one model");
is($list->[0],'TestApp::Plugin::REST::Model::User');

# on GET    '/=/model/*'     => \&list_model_keys;
$mech->get_ok('/=/model/User');
is($mech->status,'200');
$mech->get_ok('/=/model/user');
is($mech->status,'200');
$mech->get_ok('/=/model/TestApp::Plugin::REST::Model::User');
is($mech->status,'200');
$mech->get_ok('/=/model/TestApp.Plugin.REST.Model.User');
is($mech->status,'200');
$mech->get_ok('/=/model/testapp.plugin.rest.model.user');
is($mech->status,'200');

{
    $mech->get('/=/model/Usery');
    is($mech->status,'404');
}


$mech->get_ok('/=/model/User.yml');
my %keys =  %{get_content()};

is((0+keys(%keys)), 4, "The model has 4 keys");
is_deeply([sort keys %keys], [sort qw/id name email tasty/]);


# on GET    '/=/model/*/*'   => \&list_model_items;
$mech->get_ok('/=/model/user/id.yml');
my @rows = @{get_content()};
is($#rows,0);


# on GET    '/=/model/*/*/*' => \&show_item;
$mech->get_ok('/=/model/user/id/1.yml');
my %content = %{get_content()};
is_deeply(\%content, { name => 'test', email => 'test@example.com', id => 1, tasty => undef });

# on GET    '/=/model/*/*/*/*' => \&show_item_Field;
$mech->get_ok('/=/model/user/id/1/email.yml');
is(get_content(), 'test@example.com');

# on PUT    '/=/model/*/*/*' => \&replace_item;
# on DELETE '/=/model/*/*/*' => \&delete_item;
# on GET    '/=/action'      => \&list_actions;
# on GET    '/=/action/*'    => \&list_action_params;
# on POST   '/=/action/*'    => \&run_action;
# 

sub get_content { return Jifty::YAML::Load($mech->content)}

1;

