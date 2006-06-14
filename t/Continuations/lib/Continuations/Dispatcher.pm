package Continuations::Dispatcher;
use Jifty::Dispatcher -base;


before '/tutorial' => run {
    unless (Jifty->web->session->get('got_help')) {
        Jifty->web->tangent(url => '/index-help.html');
    }
    set been_helped => 1;
}

on '/tutorial' => run {
    show '/index.html';
}

on '*' => show;

1;
