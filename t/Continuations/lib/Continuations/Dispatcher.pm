package Continuations::Dispatcher;
use Jifty::Dispatcher -base;

# whitelist these read-only actions
before '*' => run {
    Jifty->api->allow('GetGrail');
    Jifty->api->allow('CrossBridge');
};

my $before = 0;
before '/tutorial' => run {
    unless (Jifty->web->session->get('got_help')) {
        Jifty->web->tangent(url => '/index-help.html');
    }
    set been_helped => ++$before;
};

on '/tutorial' => run {
    show '/index.html';
};

before '/index-help.html' => run {
    Jifty->web->session->set(got_help => 1);
};

1;
