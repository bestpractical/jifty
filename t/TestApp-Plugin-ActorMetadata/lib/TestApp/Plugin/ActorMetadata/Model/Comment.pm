use strict;
use warnings;

package TestApp::Plugin::ActorMetadata::Model::Comment;
use Jifty::DBI::Schema;

use TestApp::Plugin::ActorMetadata::Record schema {
    column body => type is 'text';
};

use Jifty::Plugin::ActorMetadata::Mixin::Model::ActorMetadata map => {
    created_by => 'creator',    
    created_on => 'created', 
};

# Your model-specific methods go here.

1;

