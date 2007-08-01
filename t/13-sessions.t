use strict;
use warnings;

=head1 DESCRIPTION

Tests Jifty::Web::Session

=cut

use Jifty::Test tests => 31;

my ($first_id, $second_id, $third_id);

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
    $second_id = $session->id;

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

# the three-arg form

{
    my $session = Jifty::Web::Session->new();
    $session->load_by_kv('user', 'first', sub { $_[0] =~ /^f/ } );
    ok($session->id, "got a session");
    is($session->id, $first_id, "first session again");
    is($session->get('number'), '1st');
}

{
    my $session = Jifty::Web::Session->new();
    $session->load_by_kv('user', 'third', sub { $_[0] =~ /\b(thi|3)rd\b/ } );
    ok($session->id, "got a session");
    $third_id = $session->id;

    isnt($session->id, $first_id,  "not first session");
    isnt($session->id, $second_id, "not second session");
    is($session->get('number'), undef);
    $session->set(number => '3rd');
    is($session->get('number'), '3rd');
}

{
    my $session = Jifty::Web::Session->new();
    $session->load_by_kv('user', 'third', sub { $_[0] =~ /\b(thi|3)rd\b/ } );
    ok($session->id, "got a session");
    isnt($session->id, $first_id,  "not first session");
    isnt($session->id, $second_id, "not second session");
    is($session->id,   $third_id, "third session again");
    is($session->get('number'), '3rd');
}

