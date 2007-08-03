use strict;
use warnings;

package TestApp::Plugin::Chart::View;
use Jifty::View::Declare -base;

template '/graphit' => page {
    Jifty->web->chart(
        type   => 'Pie',
        width  => '100%',
        height => 500,
        data   => sub {
            [
                [ 2004, 2005, 2006, 2007 ],
                [ 26, 37, 12, 42 ]
            ];
        },
    );
};

1;
