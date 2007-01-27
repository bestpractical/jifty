package TestApp::View;
use warnings;
use strict;

use Jifty::View::Declare -base;

template 'concrete2.html' => sub  {
   html {
   body {
    h1 { _( 'I have %1 concrete mixers', 2) };
    }
    }
};

1;
