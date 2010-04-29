#!/usr/bin/env perl
use warnings;
use strict;

use Jifty::Test::Dist tests => 103, actual_server => 1;
use Jifty::Test::WWW::Mechanize;

my $server  = Jifty::Test->make_server;
isa_ok($server, 'Jifty::TestServer');

my $URL     = $server->started_ok;
my $mech    = Jifty::Test::WWW::Mechanize->new();
$mech->requests_redirectable([]);

ok(1, 'Loaded the test script');

my $g1 = TestApp::Plugin::REST::Model::Group->new(
    current_user => TestApp::Plugin::REST::CurrentUser->superuser );
$g1->create( name => 'test group' );
ok( $g1->id );

my $u1 = TestApp::Plugin::REST::Model::User->new(
    current_user => TestApp::Plugin::REST::CurrentUser->superuser,
);
$u1->create(name => 'test', email => 'test@example.com', group_id => $g1->id);
ok($u1->id);

our $FORMAT_NUMBER;

sub result_of {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $request = shift;
    my $test    = shift;

    if (!ref($request)) {
        $request = {
            mech_method => 'get',
            url         => $request,
        };
    }

    my %loaders = (
        yml  => \&Jifty::YAML::Load,
        json => \&Jifty::JSON::decode_json,
        js   => sub {
            my $js = shift;
            $js =~ s/.*? = //; # variable assignment
            return Jifty::JSON::decode_json($js);
        },
    );

    local $FORMAT_NUMBER = 0;
    for my $format (keys %loaders) {
        $FORMAT_NUMBER++;

        my $url = $URL . $request->{url} . '.' . $format;

        my $method = $request->{mech_method};
        my $response = $mech->$method($url, @{ $request->{mech_args} || [] });

        ok($response->is_success || $response->is_redirect, "$method successful");
        my @contents = $response->content;

        if (my $location = $response->header('Location')) {
            $response = $mech->get($location);
            ok($response->is_success, "redirect successful");
            push @contents, $response->content;
        }

        local $Test::Builder::Level = $Test::Builder::Level + 1;

        eval {
            @contents = map { scalar $loaders{$format}->($_) } @contents;
        };
        fail($@) if $@;

        $test->(@contents);
    }
}

sub result_of_post {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $request    = shift;
    my $parameters = shift;
    my $test       = shift;

    if (!ref($request)) {
        $request = {
            mech_method => 'post',
            mech_args   => [$parameters],
            url         => $request,
        };
    }

    result_of($request, $test);
}

result_of '/=/model' => sub {
    is_deeply($_[0], [
        'TestApp.Plugin.REST.Model.Group',
        'TestApp.Plugin.REST.Model.User',
    ]);
};

result_of '/=/model/User' => sub {
    is(scalar keys %{ $_[0] }, 5, '5 keys in the user record');
};

result_of '/=/model/user/id' => sub {
    is(@{ $_[0] }, 1, "one user");
};

result_of '/=/model/user/id/1' => sub {
    is_deeply($_[0], {
        name  => 'test',
        email => 'test@example.com',
        id    => 1,
        tasty => undef,
        group_id => 1,
        group => { name => 'test group', id => 1 },
    });
};

result_of '/=/model/user/id/1/email' => sub {
    is($_[0], 'test@example.com');
};

result_of_post '/=/model/user' => {
    name => 'moose',
    email => 'moose@example.com',
} => sub {
    my ($action_result, $record) = @_;

    my $id = 2 + ($FORMAT_NUMBER - 1);

    is_deeply($action_result, {
        action_class   => 'TestApp::Plugin::REST::Action::CreateUser',
        content        => { id => $id },
        error          => undef,
        failure        => 0,
        field_errors   => {},
        field_warnings => {},
        message        => 'Created',
        success        => 1,
    });

    is_deeply($record, {
        email => 'moose@example.com',
        id    => $id,
        name  => 'moose',
        tasty => undef,
        group_id => undef,
        group => undef,
    });
};


# on PUT    '/=/model/*/*/*' => \&replace_item;
# on DELETE '/=/model/*/*/*' => \&delete_item;

# on POST   '/=/model/*'     => \&create_item;
$mech->post( $URL . '/=/model/User', { name => "moose", email => 'moose@example.com' } );
is($mech->status, 302, "create via POST to model worked");

$mech->post( $URL . '/=/model/Group', { name => "moose" } );
is($mech->status, 403, "create via POST to model with disallowed create action failed with 403");

TODO: {
    local $TODO = 'Missing mandatory field fails with error 500 on debian unstable (nov 2009), test is commented out to keep time';
#$mech->post( $URL . '/=/model/Group', { } );
#is($mech->status, 403, "create via POST with missing mandatory field");
    ok(0, $TODO);
}

# on GET    '/=/search/*/**' => \&search_items;
$mech->get_ok('/=/search/user/id/1.yml');
my $content = get_content();
is_deeply($content, [{ name => 'test', email => 'test@example.com', id => 1, tasty => undef, group_id => 1, group => { name => 'test group', id => 1 } }]);

$mech->get_ok('/=/search/user/id/1/name/test.yml');
$content = get_content();
is_deeply($content, [{ name => 'test', email => 'test@example.com', id => 1, tasty => undef, group_id => 1, group => { name => 'test group', id => 1  } }]);

$mech->get_ok('/=/search/user/id/1');
$content = get_content();
unlike($content, qr/HASH/);
like($content, qr/test\@example.com/);

$mech->get_ok('/=/search/user/id/1.html');
$content = get_content();
like($content, qr/test\@example.com/);

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

my %content;
eval {
    %content = %{get_content()};
};

ok($content{success});
is($content{message}, 'Something happened!');

    
$mech->post ( $URL . '/=/action/DoSomething.yaml', { email => 'bad@email.com' } );

eval {
    %content = %{get_content()};
};

ok(!$content{success}, "Action that doesn't validate fails");
is($content{field_errors}{email}, 'Bad looking email');


sub get_content { return Jifty::YAML::Load($mech->content)}

1;

