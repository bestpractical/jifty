use strict;
use warnings;

use Test::More tests => 17;
use Jifty::Test::Dist;
my ( $user_foo, $user_bar );

$user_foo = TestApp::Plugin::ActorMetadata::Model::User->new;
$user_foo->create( name => 'foo', email => 'foo@example.com' );
ok( $user_foo->id, 'created user foo' );

$user_bar = TestApp::Plugin::ActorMetadata::Model::User->new;
$user_bar->create( name => 'bar', email => 'bar@example.com' );
ok( $user_bar->id, 'created user bar' );

# create a post with current user foo
my $post =
  TestApp::Plugin::ActorMetadata::Model::Post->new( current_user => $user_foo );
$post->create( title => 'foo' );
ok( $post->id, 'created a post' );
is( $post->created_by->id, $user_foo->id, 'created_by is set' );

# XXX TODO update_by can't be refers to user :/
# see Jifty::Plugin::ActorMetadata::Mixin::Model::ActorMetadata
is( $post->updated_by, $user_foo->id, 'updated_by is set' );

my $now        = Jifty::DateTime->now;
my $created_on = $post->created_on;
ok( abs( $created_on->epoch - $now->epoch < 2 ),       'created_on is set' );
ok( abs( $post->updated_on->epoch - $now->epoch < 2 ), 'created_on is set' );

sleep 3;    # just let time pass

# update by foo
$post->set_title( 'foo 2' );
is( $post->title,             'foo 2',            'updated title' );
is( $post->created_by->id,    $user_foo->id,      'created_by is not updated' );
is( $post->created_on->epoch, $created_on->epoch, 'created_on is not updated' );

is( $post->updated_by, $user_foo->id, 'updated_by is not updated' );
ok( abs( $post->updated_on->epoch - Jifty::DateTime->now->epoch ) < 1 ,
    'update_on is updated correctly' );
sleep 3;
# update by bar
$post->current_user($user_bar);

$post->set_title( 'bar' );
is( $post->title,             'bar',              'updated title' );
is( $post->created_by->id,    $user_foo->id,      'created_by is not updated' );
is( $post->created_on->epoch, $created_on->epoch, 'created_on is not updated' );

is( $post->updated_by, $user_bar->id, 'updated_by is not updated' );
ok( abs( $post->updated_on->epoch - Jifty::DateTime->now->epoch ) < 2,
    'update_on is updated' );
