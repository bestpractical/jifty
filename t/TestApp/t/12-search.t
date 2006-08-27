#!/usr/bin/env perl
use strict;
use warnings;

=head1 DESCRIPTION

Test Jifty::Action::Record::Search

=cut

use lib 't/lib';
use lib 't/lib';
use Jifty::SubTest;

use Jifty::Test qw(no_plan);

my $user = TestApp::Model::User->new(current_user => TestApp::CurrentUser->superuser);

ok($user->create(
        name       => 'test1',
        email      => 'test1@localhost',
        password    => 'secret',
        tasty      => 0,
        created_on => '2006-07-08 19:30'
    ),
   "Created one user"
);

$user = TestApp::Model::User->new(current_user => TestApp::CurrentUser->superuser);

ok($user->create(
        name       => 'test2',
        email      => 'test2@example.com',
        password    => 'password',
        tasty      => 1,
        created_on => '2005-09-02 15:16'
    ),
   "Created another user"
);


$user = TestApp::Model::User->new(current_user => TestApp::CurrentUser->superuser);

ok($user->create(
        name       => 'third_test',
        email      => 'test3@not.a.domain',
        password    => 'hahaha',
        created_on => '1999-12-31 23:59'
    ),
   "Created a third user"
);


# Set up Jifty so we can call J->w->new_action
Jifty->new;
Jifty->web->request(Jifty::Request->new);
Jifty->web->response(Jifty::Response->new);

my $search = Jifty->web->new_action(
    class        => 'SearchUser',
    moniker      => 'search',
    current_user => TestApp::CurrentUser->superuser,
    arguments    => {}
);

isa_ok($search, 'Jifty::Action::Record::Search');

my %args = %{$search->arguments};

ok($args{name}, "Can search on name");
ok(!$args{name}{mandatory}, "Fields aren't mandatory");
ok($args{email}, "Can search on email");
ok($args{tasty}, "Can search on tastiness");
ok($args{created_on}, "Can search on created_on");
ok(!$args{password}, "Can't search on password");


# Search on name
$search->argument_values({name => 'test1'});
$search->run;

my $result = $search->result->content('search');

isa_ok($result, 'Jifty::Collection');
is($result->count, 1);
is($result->first->name, 'test1');

# Search on email 
$search->argument_values({email => 'test2@example.com'});
$search->run;

$result = $search->result->content('search');

isa_ok($result, 'Jifty::Collection');
is($result->count, 1);
is($result->first->name, 'test2');

# Search on tastiness
$search->argument_values({tasty => 1});
$search->run;

$result = $search->result->content('search');

isa_ok($result, 'Jifty::Collection');
is($result->count, 1);
is($result->first->name, 'test2');

# Search for a NULL tastiness
$search->argument_values({tasty => undef});
$search->run;

$result = $search->result->content('search');

isa_ok($result, 'Jifty::Collection');
is($result->count, 1);
is($result->first->name, 'third_test');

# An empty search should return everything
$search->argument_values({});
$search->run;

$result = $search->result->content('search');

isa_ok($result, 'Jifty::Collection');
is($result->count, 3);

# We ignore empty but defined fields

$search->argument_values({email => "", name => 'third_test'});
$search->run;

$result = $search->result->content('search');

isa_ok($result, 'Jifty::Collection');
is($result->count, 1);
is($result->first->name, 'third_test');
