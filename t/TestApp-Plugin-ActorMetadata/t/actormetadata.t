use strict;
use warnings;

use Test::More tests => 26;
use Jifty::Test::Dist;
my ( $user_foo, $user_bar );

my $has_mock_time;
eval "use Test::MockTime qw/set_relative_time/";
$has_mock_time = 1 unless $@;

$user_foo = TestApp::Plugin::ActorMetadata::Model::User->new->as_superuser;
$user_foo->create( name => 'foo', email => 'foo@example.com' );
ok( $user_foo->id, 'created user foo' );

$user_bar = TestApp::Plugin::ActorMetadata::Model::User->new->as_superuser;
$user_bar->create( name => 'bar', email => 'bar@example.com' );
ok( $user_bar->id, 'created user bar' );

# create a post with current user foo
my $post =
  TestApp::Plugin::ActorMetadata::Model::Post->new( current_user => $user_foo );
$post->create( title => 'foo' );
ok( $post->id, 'created a post' );
is( $post->created_by->id, $user_foo->id, 'created_by is set' );

# see Jifty::Plugin::ActorMetadata::Mixin::Model::ActorMetadata
is( $post->updated_by->id, $user_foo->id, 'updated_by is set' );

my $now        = Jifty::DateTime->now;
my $created_on = $post->created_on;
ok( abs( $created_on->epoch - $now->epoch < 2 ),       'created_on is set' );
ok( abs( $post->updated_on->epoch - $now->epoch < 2 ), 'created_on is set' );

mysleep( 3 );    # just let time pass

# update by foo
$post->set_title( 'foo 2' );
is( $post->title,             'foo 2',            'updated title' );
is( $post->created_by->id,    $user_foo->id,      'created_by is not updated' );
is( $post->created_on->epoch, $created_on->epoch, 'created_on is not updated' );

is( $post->updated_by->id, $user_foo->id, 'updated_by is not updated' );
ok( abs( $post->updated_on->epoch - Jifty::DateTime->now->epoch ) < 1 ,
    'update_on is updated correctly' );
mysleep( 3 );
# update by bar
$now = Jifty::DateTime->now;
$post->current_user($user_bar);

$post->set_title( 'bar' );
is( $post->title,             'bar',              'updated title' );
is( $post->created_by->id,    $user_foo->id,      'created_by is not updated' );
is( $post->created_on->epoch, $created_on->epoch, 'created_on is not updated' );

is( $post->updated_by->id, $user_bar->id, 'updated_by is not updated' );
ok( $post->updated_on->epoch >= $now->epoch,
    'update_on is updated' );

# creator and created are columns of comment, post doesn't have those
for my $method (qw/creator created/) {
    ok( !$post->can($method), "no method $method" );
}

my $comment =
  TestApp::Plugin::ActorMetadata::Model::Comment->new( current_user => $user_foo );

$now = Jifty::DateTime->now;
$comment->create();
ok( $comment->id, 'created a comment' );
is( $comment->creator->id, $user_foo->id, 'creator is set' );
ok( abs( $comment->created->epoch - $now->epoch < 2 ), 'created is set' );

for my $method (qw/created_by created_on updated_by updated_on/) {
    ok( !$comment->can($method), "no method $method" );
}


sub mysleep {
    my $second = shift;
    if ( $has_mock_time ) {
        set_relative_time( $second );
    }
    else {
        sleep $second;
    }
}
