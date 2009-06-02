package TestApp::Plugin::REST::Dispatcher;
use Jifty::Dispatcher -base;

before '*' => run {
    Jifty->api->deny('CreateGroup');
    Jifty->api->hide('DeleteGroup');
    Jifty->api->allow('DoSomething');
};

1;
