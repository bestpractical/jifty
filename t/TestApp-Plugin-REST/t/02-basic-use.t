#!/usr/bin/env perl

use warnings;
use strict;

=head1 DESCRIPTION

This is a template for your own tests. Copy it and modify it.

=cut

use lib 'plugins/REST/lib';

use lib 't/lib';
use Jifty::SubTest;

use Jifty::Test tests => 60;
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

my @actions = qw(TestApp::Plugin::REST::Action::CreateUser
                 TestApp::Plugin::REST::Action::UpdateUser
                 TestApp::Plugin::REST::Action::DeleteUser
                 TestApp::Plugin::REST::Action::DoSomething
                 Jifty::Action::Autocomplete
                 Jifty::Action::Redirect);

$mech->get_ok('/=/action/');
is($mech->status, 200);

for (@actions) {
    $mech->content_contains($_);
}

$mech->get_ok('/=/action.yml');
my @got = @{get_content()};

is(join(",",sort @actions), join(",", sort(@got)), "Got all the actions as YAML");


# on GET    '/=/action/*'    => \&list_action_params;

$mech->get_ok('/=/action/DoSomething');
is($mech->status, 200);
$mech->get_ok('/=/action/TestApp::Plugin::REST::Action::DoSomething');
is($mech->status, 200);
$mech->get_ok('/=/action/TestApp.Plugin.REST.Action.DoSomething');
is($mech->status, 200);

$mech->content_contains('email');
$mech->content_contains('Email');
$mech->content_contains('example@email.com');

$mech->get_ok('/=/action/DoSomething.yml');
is($mech->status, 200);

TODO: {
    local $TODO = "Waiting for YAML parameter lists for action";
    my %args;

    # Eval so this doesn't blow up if get_content doesn't return a hashref
    eval {
        %args = %{get_content()};
    };

    ok($args{email}, "Action has an email parameter");
    is($args{email}{label}, 'Email', 'email has the correct label');
    is($args{email}{default}, 'email@example.com', 'email has the correct default');
}


# on POST   '/=/action/*'    => \&run_action;
# 

$mech->post( $URL . '/=/action/DoSomething', { email => 'good@email.com' } );

$mech->content_contains('Something happened!');

TODO: {
    $mech->post( $URL . '/=/action/DoSomething', { email => 'bad@email.com' } );

    local $TODO = "Waiting for actions to return validation errors";
    $mech->content_contains('Bad looking email');
    $mech->content_lacks('Something happened!');

    $mech->post( $URL . '/=/action/DoSomething', { email => 'warn@email.com' } );
    
    $mech->content_contains('Warning for email');
    $mech->content_contains('Something happened!');
}

# Test YAML posts
TODO: {
    local $TODO = "Waiting for YAML posts to work right";
    
    yaml_post( $URL . '/=/action/DoSomething.yml', { email => 'good@email.com' } );

    eval {
        %content = %{get_content()};
    };

    ok($content{success});
    is($content{message}, 'Something happened');

    
    yaml_post( $URL . '/=/action/DoSomething', { email => 'bad@email.com' } );

    eval {
        %content = %{get_content()};
    };

    ok(!$content{success});
    is($content{error}, 'Bad looking email');
};


sub get_content { return Jifty::YAML::Load($mech->content)}
sub yaml_post {
    my $url = shift;
    my $data = shift;
    my $request = HTTP::Request->new('POST', $url);
    $request->header('Content-Type', 'text/yaml');
    $request->content(Jifty::YAML::Dump($data));

    $mech->request($request);
    
}

1;

