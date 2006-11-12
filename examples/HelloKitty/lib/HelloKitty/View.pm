use warnings;
use strict;

package HelloKitty::View;
use base qw/Jifty::View::Declare::Templates/;
use Template::Declare::Tags;
use Jifty::View::Declare::Templates;

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
