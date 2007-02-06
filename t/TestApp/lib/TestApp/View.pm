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


template 'die.html' => sub {
    die "this is an error";
};

1;
