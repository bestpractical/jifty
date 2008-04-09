
package TestApp::JiftyJS::Dispatcher;
use Jifty::Dispatcher -base;
use strict;
use warnings;

before '*' => run {
    Jifty->api->allow("AddTwoNumbers");
    Jifty->api->allow('Play');
    Jifty->api->allow('Play2');
};

1;

