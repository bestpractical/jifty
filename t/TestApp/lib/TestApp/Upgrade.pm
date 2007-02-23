use strict;
use warnings;

package TestApp::Upgrade;

use base qw/ Jifty::Upgrade /;
use Jifty::Upgrade;

since '0.0.2' => sub {
    rename
        table  => 'TestApp::Model::User',
        column => 'tasty',
        to     => 'really_tasty';
};

1;
