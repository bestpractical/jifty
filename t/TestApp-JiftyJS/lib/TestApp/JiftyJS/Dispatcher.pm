package TestApp::JiftyJS::Dispatcher;
use strict;
use warnings;
use Jifty::Dispatcher -base;

before '*' => run {
    Jifty->api->allow("AddTwoNumbers");
};

1;

