package TestApp::Plugin::REST::Dispatcher;
use Jifty::Dispatcher -base;

before '*' => run {
    Jifty->api->hide('CreateGroup');
    Jifty->api->allow('DoSomething');
};

1;
