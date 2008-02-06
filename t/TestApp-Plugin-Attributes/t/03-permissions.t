#!/usr/bin/env perl
use warnings;
use strict;
use lib 't/lib';
use Jifty::SubTest;
use Jifty::Test tests => 30;

my $song = TestApp::Plugin::Attributes::Model::Song->new;
my ($ok, $msg) = $song->create(
    name   => 'Hysteria',
    artist => 'Muse',
    album  => 'Absolution',
);
ok($ok, $msg);

ok($song->add_attribute(name => 'stars', content => 5), "can add attributes");
my $attr = $song->first_attribute('stars');

has_right($_) for qw/create read update delete/;

$song->set_right(create => 0);
has_right($_) for qw/create read update delete/;

$song->set_right(delete => 0);
has_right($_) for qw/create read update delete/;

$song->set_right(update => 0);
lacks_right($_, "$_ checks object's update right") for qw/create update delete/;
has_right('read', "read checks object's read right");

$song->set_right(read => 0);
lacks_right($_) for qw/create read update delete/;

$song->set_right(update => undef);
has_right($_, "$_ checks object's update right") for qw/create update delete/;
lacks_right('read', "read checks object's read right");

$song->set_right(read => undef);
has_right($_) for qw/create read update delete/;

sub has_right {
    my $right = shift;
    my $has_right = $attr->current_user_can($right, object => $song);

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    ok($has_right, shift || "current_user_can $right");
}

sub lacks_right {
    my $right = shift;
    my $has_right = $attr->current_user_can($right, object => $song);

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    ok(!$has_right, shift || "current_user_cannot $right");
}

