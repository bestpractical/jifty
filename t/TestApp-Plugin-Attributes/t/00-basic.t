#!/usr/bin/env perl
use warnings;
use strict;
use Jifty::Test::Dist tests => 12;

my $song = TestApp::Plugin::Attributes::Model::Song->new;
my ($ok, $msg) = $song->create(
    name   => 'Arco Arena',
    artist => 'Cake',
    album  => 'Comfort Eagle',
);
ok($ok, $msg);

can_ok($song, qw/attributes first_attribute add_attribute set_attribute delete_attribute/);

is($song->first_attribute('instrumental'), undef, "unknown attributes return undef for ->first_attribute");

my $attrs = $song->attributes;
isa_ok($attrs, "Jifty::Plugin::Attributes::Model::AttributeCollection", "->attributes returns an AttributeCollection");
can_ok($attrs, qw/named limit_to_object/);

ok($song->set_attribute(
    name        => 'is_instrumental',
    description => 'Is this song an instrumental?',
    content     => 1,
));

my $attr = $song->first_attribute('is_instrumental');
can_ok($attr, qw/name description content object_type object_id object/);

is($attr->name, 'is_instrumental', "name of the attribute was saved");
is($attr->description,  'Is this song an instrumental?', "description of the attribute was saved");
is($attr->content, 1, "content of the attribute was saved");

my $song2 = TestApp::Plugin::Attributes::Model::Song->new;
($ok, $msg) = $song2->create(
    name   => 'A Passage to Bangkok',
    artist => 'Rush',
    album  => '2112',
);
ok($ok, $msg);

ok(!defined($song2->first_attribute('is_instrumental')), "second song has no is_instrumental attribute");

