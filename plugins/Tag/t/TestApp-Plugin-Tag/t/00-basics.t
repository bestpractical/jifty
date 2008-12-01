#!/usr/bin/env perl
use warnings;
use strict;
use Jifty::Test::Dist tests => 12;

sub flush_nodes {
    my $nodes = Jifty->app_class('Model', 'NodeCollection')->new;
    $nodes->unlimit;
    $_->delete foreach @$nodes;
}

{
    my $node = Jifty->app_class('Model', 'Node')->new;
    my ($ok, $msg) = $node->create(
        type    => 'memo',
        subject => 'Cake',
    );
    ok $ok, $msg;

    ok !$node->has_tag('tag'), 'has no tag';

    ($ok, $msg) = $node->add_tag('tag');
    ok $ok, $msg;
    ($ok, $msg) = $node->add_tag('tag');
    ok !$ok, $msg;
    ($ok, $msg) = $node->add_tag('tag', exist_ok => 1);
    ok $ok, $msg;

    ok $node->has_tag('tag'), 'has tag';

    ($ok, $msg) = $node->delete_tag('tag');
    ok $ok, $msg;
    ($ok, $msg) = $node->delete_tag('tag');
    ok !$ok, $msg;
    ($ok, $msg) = $node->delete_tag('tag', not_exist_ok => 1);
    ok $ok, $msg;

    ok !$node->has_tag('tag'), 'has no tag';
}

{
    my $node = Jifty->app_class('Model', 'Node')->new;
    my ($ok, $msg) = $node->create(
        type    => 'memo',
        subject => 'Cake',
    );
    ok $ok, $msg;

    ($ok, $msg) = $node->add_tag('tag');
    ok $ok, $msg;

    my $nid = $node->id;

    ($ok, $msg) = $node->delete;
    ok $ok, $msg;

    my $tags = Jifty->app_class('Model', 'TagCollection')->new;
    $tags->limit( column => 'model', value => 'Node' );
    $tags->limit( column => 'record', value => $nid );
    is $tags->count, 0, "node is deleted => no tags";
}

{
    my $node = Jifty->app_class('Model', 'Node')->new;
    my ($ok, $msg) = $node->create(
        type    => 'memo',
        subject => 'Cake',
    );
    ok $ok, $msg;

    ($ok, $msg) = $node->add_tag('tag');
    ok $ok, $msg;

    my $tag = $node->has_tag('tag');
    ok $tag, "has tag";
    isa_ok $tag, Jifty->app_class('Model', 'Tag');
    is $tag->value, 'tag', 'correct value';
    is $tag->model, 'Node', 'correct model';
    is $tag->record_id, $node->id, 'correct record id';

    my $record = $tag->record;
    isa_ok $record, Jifty->app_class('Model', 'Node');
    is $record->id, $node->id, 'correct value';
}

flush_nodes();

{
    my %test_nodes = (
        '-' => [],
        'a' => ['a'],
        'b' => ['b'],
        'c' => ['c'],
        'ab' => ['a', 'b'],
        'ac' => ['a', 'c'],
        'bc' => ['b', 'c'],
        'abc' => ['a', 'b', 'c'],
    );

    while ( my ($s, $t) = each %test_nodes ) {
        my $node = Jifty->app_class('Model', 'Node')->new;
        my ($ok, $msg) = $node->create(
            type    => 'memo',
            subject => $s,
        );
        ok $ok, $msg;
        foreach ( @$t ) {
            my ($ok, $msg) = $node->add_tag($_);
            ok $ok, $msg;
        }
    }
}

{
    my $test = sub {
        my $node = Jifty->app_class('Model', 'Node')->load_by_cols( subject => shift);
        ok $node, 'loaded a node';

        my $tag = $node->has_tag(shift);
        ok $tag, 'has tag';

        my ($expect, $expect_count) = ('', 0);
        $expect = join ' ', map { $expect_count++; $_ } sort split /\s+/, pop;

        my $nodes = $tag->used_by(@_);
        is $nodes->count, $expect_count, 'correct count';
        my $str = join ' ', sort map $_->subject, @$nodes;
        is $str, $expect, 'correct list' or diag "wrong query: ". $nodes->build_select_query;
    };

    $test->('a', 'a', 'ab ac abc');
    $test->('a', 'a', include_this => 1, 'a ab ac abc');
    # XXX: need additional models to test 
}

{
    my $test = sub {
        my ($expect, $expect_count) = ('', 0);
        $expect = join ' ', map { $expect_count++; $_ } sort split /\s+/, pop;

        my $nodes = Jifty->app_class('Model', 'NodeCollection')->new;
        if ( ref $_[0] ) {
            $nodes->limit_by_tag(@$_) foreach @_;
        } else {
            $nodes->limit_by_tag(@_);
        }
        is $nodes->count, $expect_count, 'correct count';
        my $str = join ' ', sort map $_->subject, @$nodes;
        is $str, $expect, 'correct list' or diag "wrong query: ". $nodes->build_select_query;
    };

    $test->('', '-');
    $test->('!', 'a b c ab ac bc abc');
    $test->('a', 'a ab ac abc');
    $test->('!a', '- b c bc');
    $test->(['a'], ['b'], 'ab abc');
    $test->(['!a'], ['b'], 'b bc');
    $test->(['a'], ['b'], ['c'], 'abc');
    $test->(['!a'], ['b'], ['c'], 'bc');
}

