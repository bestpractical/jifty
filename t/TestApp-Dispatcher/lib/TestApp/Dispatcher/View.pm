use warnings;
use strict;

package TestApp::Dispatcher::View;
use Jifty::View::Declare -base;

template woot => page {
    if ( my $v = get('woot') ) { outs("woot: $v") }
    else { outs('woot') }
};

1;
