use warnings;
use strict;

package HelloKitty::View;
use Jifty::View::Declare -base;
use Template::Declare::Tags;

template foo => sub {
    html {
        body {
            show 'content';
        }

    }
};

template content => sub {
    form {'woot'};
};

1;
