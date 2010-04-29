#!/usr/bin/env perl

use warnings;
use strict;

=head1 DESCRIPTION

This is a template for your own tests. Copy it and modify it.

=cut

use Jifty::Test::Dist tests => 88, actual_server => 1;
use Jifty::Test::WWW::Mechanize;

my $server  = Jifty::Test->make_server;

isa_ok($server, 'Jifty::TestServer');

my $URL     = $server->started_ok;
my $mech    = Jifty::Test::WWW::Mechanize->new();

ok(1, "Loaded the test script");

my $u1 = TestApp::Plugin::REST::Model::User->new(
    current_user => TestApp::Plugin::REST::CurrentUser->superuser );
$u1->create( name => 'test', email => 'test@example.com' );
ok( $u1->id );

my $g1 = TestApp::Plugin::REST::Model::Group->new(
    current_user => TestApp::Plugin::REST::CurrentUser->superuser );
$g1->create( name => 'test group' );
ok( $g1->id );

# on GET    '/=/model'       => \&list_models;

$mech->get_ok("$URL/=/model.yml", "Got model list");
my $list = Jifty::YAML::Load($mech->content);
is(scalar @$list, 2, "Got two models");
is($list->[0],'TestApp.Plugin.REST.Model.Group');
is($list->[1],'TestApp.Plugin.REST.Model.User');

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

is((0+keys(%keys)), 5, "The model has 5 keys");
is_deeply([sort keys %keys], [sort qw/group_id id name email tasty/]);
is_deeply($keys{'group_id'}{serialized_as}, { name => 'group', columns => [qw(id name)] });

# on GET    '/=/model/*/*'   => \&list_model_items;
$mech->get_ok('/=/model/user/id.yml');
my @rows = @{get_content()};
is($#rows,0);


# on GET    '/=/model/*/*/*' => \&show_item;
$mech->get_ok('/=/model/user/id/1.yml');
my %content = %{get_content()};
is_deeply(\%content, { name => 'test', email => 'test@example.com', id => 1, tasty => undef, group_id => undef, group => undef });

# on GET    '/=/model/*/*/*/*' => \&show_item_Field;
$mech->get_ok('/=/model/user/id/1/email.yml');
is(get_content(), 'test@example.com');

# on PUT    '/=/model/*/*/*' => \&replace_item;
# on DELETE '/=/model/*/*/*' => \&delete_item;

# on POST   '/=/model/*'     => \&create_item;
$mech->post( $URL . '/=/model/User', { name => "moose", email => 'moose@example.com' } );
is($mech->status, 200, "create via POST to model worked");

my $response = $mech->post( $URL . '/=/model/Group', { } );
ok(!$response->is_success, "create via POST to model with disallowed create action failed");

# on GET    '/=/search/*/**' => \&search_items;
$mech->get_ok('/=/search/user/id/1.yml');
my $content = get_content();
is_deeply($content, [{ name => 'test', email => 'test@example.com', id => 1, tasty => undef, group_id => undef, group => undef }]);

$mech->get_ok('/=/search/user/__not/id/1.yml');
$content = get_content();
is_deeply($content, [{ name => 'moose', email => 'moose@example.com', id => 2, tasty => undef, group_id => undef, group => undef }]);

$mech->get_ok('/=/search/user/id/1/name/test.yml');
$content = get_content();
is_deeply($content, [{ name => 'test', email => 'test@example.com', id => 1, tasty => undef, group_id => undef, group => undef }]);

$u1->set_group_id($g1->id);
is($u1->group_id, $g1->id);
is($u1->group->id, $g1->id);

$mech->get_ok('/=/search/user/id/1/name/test.yml');
$content = get_content();
is_deeply($content, [{ name => 'test', email => 'test@example.com', id => 1, tasty => undef, group_id => $g1->id, group => { id => $g1->id, name => 'test group'} }]);


$mech->get_ok('/=/search/user/id/1/name/test/email.yml');
$content = get_content();
is_deeply($content, ['test@example.com']);

$mech->get('/=/search/Usery/id/1.yml');
is($mech->status,'404');

$mech->get('/=/search/user/id/1/name/foo.yml');
is($mech->status,'200');
$content = get_content();
is_deeply($content, []);

# on GET    '/=/action'      => \&list_actions;

my @actions = qw(
                 TestApp.Plugin.REST.Action.CreateGroup
                 TestApp.Plugin.REST.Action.UpdateGroup
                 TestApp.Plugin.REST.Action.SearchGroup
                 TestApp.Plugin.REST.Action.ExecuteGroup
                 TestApp.Plugin.REST.Action.CreateUser
                 TestApp.Plugin.REST.Action.UpdateUser
                 TestApp.Plugin.REST.Action.DeleteUser
                 TestApp.Plugin.REST.Action.SearchUser
                 TestApp.Plugin.REST.Action.ExecuteUser
                 TestApp.Plugin.REST.Action.DoSomething
                 Jifty.Action.Autocomplete
                 Jifty.Action.Redirect);

$mech->get_ok('/=/action/');
is($mech->status, 200);
for (@actions) {
    $mech->content_contains($_);
}
$mech->get_ok('/=/action.yml');
my @got = @{get_content()};

is(
    join(",", sort @got ),
    join(",",sort @actions), 
, "Got all the actions as YAML");


# on GET    '/=/action/*'    => \&list_action_params;

$mech->get_ok('/=/action/DoSomething');
is($mech->status, 200);
$mech->get_ok('/=/action/TestApp::Plugin::REST::Action::DoSomething');
is($mech->status, 200);
$mech->get('/=/action/TestApp.Plugin.REST.Action.DoSomethingBad');
is($mech->status, 404);
$mech->get_ok('/=/action/TestApp.Plugin.REST.Action.DoSomething');
is($mech->status, 200);

# Parameter name
$mech->content_contains('email');
# Parameter label
$mech->content_contains('Email');
# Default value
$mech->content_contains('example@email.com');

$mech->get_ok('/=/action/DoSomething.yml');
is($mech->status, 200);

my %args = %{get_content()};
ok($args{email}, "Action has an email parameter");
is($args{email}{label}, 'Email', 'email has the correct label');
is($args{email}{default_value}, 'example@email.com', 'email has the correct default');


# on POST   '/=/action/*'    => \&run_action;
# 

$mech->post( $URL . '/=/action/DoSomething', { email => 'good@email.com' } );

$mech->content_contains('Something happened!');

$mech->post( $URL . '/=/action/DoSomething', { email => 'bad@email.com' } );

$mech->content_contains('Bad looking email');
$mech->content_lacks('Something happened!');

$mech->post( $URL . '/=/action/DoSomething', { email => 'warn@email.com' } );
    
$mech->content_contains('Warning for email');
$mech->content_contains('Something happened!');

# Test YAML posts
$mech->post ( $URL . '/=/action/DoSomething.yml', { email => 'good@email.com' } );

eval {
    %content = %{get_content()};
};

ok($content{success});
is($content{message}, 'Something happened!');

# Test XML posts
$mech->post ( $URL . '/=/action/DoSomething.xml', { email => 'good@email.com' } );

$mech->content_like(qr'<message>Something happened!</message>');

$mech->post ( $URL . '/=/action/DoSomething.yaml', { email => 'bad@email.com' } );

eval {
    %content = %{get_content()};
};

ok(!$content{success}, "Action that doesn't validate fails");
is($content{field_errors}{email}, 'Bad looking email');


sub get_content { return Jifty::YAML::Load($mech->content)}

1;

