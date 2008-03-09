use strict;
use warnings;

package TestApp::Plugin::Comments::Model::BlogPost;
use Jifty::DBI::Schema;

use constant CLASS_UUID => '21EC717C-A2D3-11DC-BDD3-A201F3F60BF3';

use TestApp::Plugin::Comments::Record schema {
    column title => type is 'text';
    column body => type is 'text';
    column author => type is 'text';
    column posted => type is 'text';
};

use Jifty::Plugin::Comment::Mixin::Model::Commented;

# Your model-specific methods go here.

1;

