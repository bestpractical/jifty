#!/usr/bin/env perl
use warnings;
use strict;
use Jifty::Test::Dist tests => 7;

my $song = TestApp::Plugin::Attributes::Model::Song->new;
my ($ok, $msg) = $song->create(
    name   => 'Home',
    artist => 'Dream Theater',
    album  => 'Scenes from a Memory',
);
ok($ok, $msg);

$song->add_attribute(name => 'artists', content => [qw/LaBrie Myung Petrucci Portroy Rudess/]);
is_deeply($song->first_attribute('artists')->content, [qw/LaBrie Myung Petrucci Portroy Rudess/], "attribute content can be an arrayref");

$song->add_attribute(name => 'guests', content => {Thomason => "additional vocals", Brown => "hypnotherapist"});
is_deeply($song->first_attribute('guests')->content, {Thomason => "additional vocals", Brown => "hypnotherapist"}, "attribute content can be a hashref");

is($song->attributes->count, 2, "two attributes");
is($song->attributes->named('artists')->count, 1, "one attribute named artists");
is($song->attributes->named('guests')->count, 1, "one attribute named guests");

my $complex = {
    a => [qw/a b c/],
    b => {
        c => 'd',
        e => [qw/f g h/],
        i => {
            j => 'k',
            l => 'm',
        },
        n => [],
    },
    o => undef,
};

$song->add_attribute(
    name => 'complex',
    content => $complex,
);

is_deeply($song->first_attribute('complex')->content, $complex, "complex content can be saved");

