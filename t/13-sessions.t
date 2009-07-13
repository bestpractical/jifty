use strict;
use warnings;

=head1 DESCRIPTION

Tests Jifty::Web::Session

=cut

use Jifty::Test tests => 21;

{
    my $session = Jifty::Model::Session->new;
    $session->create(
        data_key => 'old',
        value    => 'one',
    );
    $session->set_created( DateTime->now->subtract( days => 14 ) );
    $session->set_updated( DateTime->now->subtract( days => 14 ) );

    my $collection = Jifty::Model::SessionCollection->new;
    $collection->expired_update( DateTime->now->subtract( days => 2 ) );
    is($collection->first->value,'one');

    $collection->unlimit;
    $collection->expired_create( DateTime->now->subtract( days => 2 ) );
    is($collection->first->value,'one');
}

my ($first_id, $third_id);

{
    my $session = Jifty::Web::Session->new();
    $session->load_by_kv(user => 'first');
    ok($session->id, "got a session");
    $first_id = $session->id;

    $session->set(hello => 'world');
    $session->set(number => '1st');

    is($session->get('hello'),  'world', "immediate 'get' works");
    is($session->get('number'), '1st',   "immediate 'get' works");

    $session->load_by_kv(user => 'first');
    is($session->id, $first_id, "same session as before");
    is($session->get('hello'),  'world', "'get' before destroy works");
    is($session->get('number'), '1st',   "'get' before destroy works");
}

{
    my $session = Jifty::Web::Session->new();
    $session->load_by_kv(user => 'first');
    ok($session->id, "got a session");
    is($session->id, $first_id, "same session as before");

    is($session->get('hello'),  'world', "'set', destroy, 'get' works");
    is($session->get('number'), '1st',   "'set', destroy, 'get' works");
}

{
    my $session = Jifty::Web::Session->new();
    $session->load_by_kv(user => 'second');
    ok($session->id, "got a session");
    isnt($session->id, $first_id, "NOT same session as before");

    is($session->get('hello'),  undef, "different value gives different session");
    is($session->get('number'), undef, "different value gives different session");

    $session->set(hello => 'world');
    $session->set(number => '2nd');
}

{
    my $session = Jifty::Web::Session->new();
    $session->load_by_kv(user => 'first');
    ok($session->id, "got a session");
    is($session->id, $first_id, "first session again");

    is($session->get('hello'), 'world');
    is($session->get('number'), '1st', "even though the two sessions have some overlapping keys, the one that matters doesn't overlap");
}

# test null char
TODO:
{
    local $TODO = "something doesn't like \\0, and it generates a lot of warnings, so the tests here are commented out instead of todo'd";
    ok(0, $TODO);
}

#{
#    my $session = Jifty::Web::Session->new();
#    $session->load_by_kv(user => "first\0sneaky!");
#    ok($session->id, "got a session");
#    isnt($session->id, $first_id, "'first\\0sneaky!' different from 'first'");
#    is($session->get('hello'), undef, "first\\0sneaky has no session data yet");
#}
#
#{
#    my $session = Jifty::Web::Session->new();
#    $session->load_by_kv(user => "\0third");
#    ok($session->id, "got a session");
#    $third_id = $session->id;
#
#    $session->set(a => 'apple');
#}
#
#{
#    my $session = Jifty::Web::Session->new();
#    $session->load_by_kv(user => "\0third");
#    ok($session->id, "got a session");
#    is($session->id, $third_id, "same session as before");
#
#    is($session->get('a'), 'apple', "'set', destroy, 'get' works");
#}
#
