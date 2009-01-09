use strict;
use warnings;

package TestApp::Plugin::ActorMetadata::Model::Post;
use Jifty::DBI::Schema;

use TestApp::Plugin::ActorMetadata::Record schema {
    column
      title => type is 'text',
      label is 'Title',
      default is 'Untitled post';
};

use Jifty::Plugin::ActorMetadata::Mixin::Model::ActorMetadata;

# Your model-specific methods go here.

1;

