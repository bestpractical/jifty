package TestApp::View;
use warnings;
use strict;

use Jifty::View::Declare -base;
use Jifty::View::Declare::Helpers;

template 'index.html' => page { 
    { title is 'tdpage_test' }
    h2 { "TDPAGE" };
};

1;

