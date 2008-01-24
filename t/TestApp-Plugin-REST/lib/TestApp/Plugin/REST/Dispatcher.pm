package TestApp::Plugin::REST::Dispatcher;
use Jifty::Dispatcher -base;

before '*' => run {
    Jifty->api->allow('DoSomething');
};

1;
