#!/usr/bin/env perl
use warnings;
use strict;

=head1 DESCRIPTION

A basic test harness for the BlogPost model.

=cut

use Test::More;
BEGIN {
    if (eval { require HTML::Scrubber; require MIME::Base64::URLSafe; require Regexp::Common::Email::Address; 1 }) {
        plan tests => 16;
    }
    else {
        plan skip_all => 'A requirement of the Comment plugin is not installed.';
    }
}

use lib 't/lib';
use Jifty::SubTest;

use Jifty::Test;

# Make sure we can load the model
use_ok('TestApp::Plugin::Comments::Model::BlogPost');

# Grab a system user
my $system_user = TestApp::Plugin::Comments::CurrentUser->superuser;
ok($system_user, "Found a system user");

# Try testing a create
my $o = TestApp::Plugin::Comments::Model::BlogPost->new(current_user => $system_user);
my ($id) = $o->create();
ok($id, "BlogPost create returned success");
ok($o->id, "New BlogPost has valid id set");
is($o->id, $id, "Create returned the right id");

my $c_list = $o->comments;
is($c_list->count, 0, 'We have zippo comments');

# Add a comment
my $c = TestApp::Plugin::Comments::Model::Comment->new(current_user => $system_user);
$c->create(
    title      => 'Jifty is da bomb',
    body       => 'And other overused clichés...',
    created_on => DateTime->now,
    your_name  => 'Sterling',
);
ok($c->id, 'Created a comment');

my $bpc = TestApp::Plugin::Comments::Model::BlogPostComment->new(current_user => $system_user);
$bpc->create(
    commented_upon => $o->id,
    the_comment    => $c->id,
);
ok($bpc->id, 'Created a comment link');

$c_list->redo_search;
is($c_list->count, 1, 'We have a comment!');
is($c_list->count_all, 1, 'We have a comment somewhere!');

# And another
$o->create();
ok($o->id, "BlogPost create returned another value");
isnt($o->id, $id, "And it is different from the previous one");

# Searches in general
my $collection =  TestApp::Plugin::Comments::Model::BlogPostCollection->new(current_user => $system_user);
$collection->unlimit;
is($collection->count, 2, "Finds two records");

# Searches in specific
$collection->limit(column => 'id', value => $o->id);
is($collection->count, 1, "Finds one record with specific id");

# Delete one of them
$o->delete;
$collection->redo_search;
is($collection->count, 0, "Deleted row is gone");

# And the other one is still there
$collection->unlimit;
is($collection->count, 1, "Still one left");

