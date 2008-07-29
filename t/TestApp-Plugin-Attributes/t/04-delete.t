#!/usr/bin/env perl
use warnings;
use strict;
use Jifty::Test::Dist tests => 8;

my $song = TestApp::Plugin::Attributes::Model::Song->new;
my ($ok, $msg) = $song->create(
    name   => 'Backdrifts',
    artist => 'Radiohead',
    album  => 'Hail to the Thief',
);
ok($ok, $msg);
my $song_id = $song->id;

my $song2 = TestApp::Plugin::Attributes::Model::Song->new;
($ok, $msg) = $song2->create(
    name   => '15 Step',
    artist => 'Radiohead',
    album  => 'In Rainbows',
);
ok($ok, $msg);
my $song2_id = $song2->id;

for (qw/httt radiohead/) {
    $song->add_attribute(name => 'tag', content => $_);
    $song2->add_attribute(name => 'tag', content => $_);
}

$song->add_attribute(name => 'tag', content => 2003);
$song2->add_attribute(name => 'tag', content => 2007);

my %got = map { $_->content => 1 }
          @{ $song->attributes->named("tag")->items_array_ref };

::is_deeply(\%got,
            {httt => 1, radiohead => 1, 2003 => 1},
            "attributes set correctly");

($ok, $msg) = $song->delete;
ok($ok, $msg);

my $attrs = TestApp::Plugin::Attributes::Model::AttributeCollection->new(
    current_user => Jifty::CurrentUser->superuser,
);
$attrs->limit(
    column => 'object_type',
    value => 'TestApp::Plugin::Attributes::Model::Song',
);
$attrs->limit(
    column => 'object_id',
    value => $song_id,
);

is($attrs->count, 0, "deleted all the attributes of the song");

$attrs = TestApp::Plugin::Attributes::Model::AttributeCollection->new(
    current_user => Jifty::CurrentUser->superuser,
);
$attrs->limit(
    column => 'object_type',
    value => 'TestApp::Plugin::Attributes::Model::Song',
);
$attrs->limit(
    column => 'object_id',
    value => $song2_id,
);

is($attrs->count, 3, "delete only affects the one deleted object deleted");

$ok = $song2->delete_all_attributes;
ok($ok, "reported success in deleting all attributes");

$attrs = TestApp::Plugin::Attributes::Model::AttributeCollection->new(
    current_user => Jifty::CurrentUser->superuser,
);
$attrs->limit(
    column => 'object_type',
    value => 'TestApp::Plugin::Attributes::Model::Song',
);
$attrs->limit(
    column => 'object_id',
    value => $song2_id,
);

is($attrs->count, 0, "delete_all_attributes successful");

