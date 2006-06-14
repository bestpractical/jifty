package Continuations::Dispatcher;
use Jifty::Dispatcher -base;


before '/tutorial' => run {
    unless (Jifty->web->session->get('got_help')) {
        Jifty->web->tangent(url => '/index-help.html');
    }
    set been_helped => 1;
};

on '/tutorial' => run {
    show '/index.html';
};

before '/index-help.html' => run {
    Jifty->web->session->set(got_help => 1);
};

on '*' => show;

1;
