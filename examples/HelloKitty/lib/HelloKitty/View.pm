

package HelloKitty::View;
use base qw/Jifty::View::Declare::Templates/;
use Template::Declare::Tags;

template foo => sub {
    html {
        body {
            show 'content';
        }

    }
};

template content => sub {
    outs 'woot';

};

1;
