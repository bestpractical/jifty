use strict;
use warnings;

# test the actormetadata model mixin works well with model which has other mixins.

use Test::More tests => 1;
use Jifty::Test::Dist;

is_deeply(
[sort map { $_->name } TestApp::Plugin::ActorMetadata::Model::Evil->columns],
[qw(created_by created_on id my_mixin_hello updated_by updated_on)]);
