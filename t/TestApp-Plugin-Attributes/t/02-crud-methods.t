#!/usr/bin/env perl
use warnings;
use strict;
use lib 't/lib';
use Jifty::SubTest;
use Jifty::Test tests => 8;

my $song = TestApp::Plugin::Attributes::Model::Song->new;
my ($ok, $msg) = $song->create(
    name   => 'Backdrifts',
    artist => 'Radiohead',
    album  => 'Hail to the Thief',
);
ok($ok, $msg);

$song->add("radiohead");
$song->has_tags(qw/radiohead/);

$song->add("2003");
$song->has_tags(qw/radiohead 2003/);

$song->set("httt");
$song->has_tags(qw/httt/);

$song->add("radiohead");
$song->has_tags(qw/httt radiohead/);

$song->add("2003");
$song->has_tags(qw/httt radiohead 2003/);

$song->delete_attribute('tag');
$song->has_tags(qw//);

$song->add("radiohead");
$song->has_tags(qw/radiohead/);

sub TestApp::Plugin::Attributes::Model::Song::add {
    $_[0]->add_attribute(name => 'tag', content => $_[1]);
}

sub TestApp::Plugin::Attributes::Model::Song::set {
    $_[0]->set_attribute(name => 'tag', content => $_[1]);
}

sub TestApp::Plugin::Attributes::Model::Song::has_tags {
    my $self     = shift;
    my %expected = map { $_ => 1 } @_;
    my %got      = map { $_->content => 1 }
                   @{ $self->attributes->named("tag")->items_array_ref };

    ::is_deeply(\%got, \%expected, "attributes set correctly");
}

