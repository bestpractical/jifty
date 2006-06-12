package Continuations::Dispatcher;
use Jifty::Dispatcher -base;


before '/help' => run {
    Jifty->web->tangent(url => '/index-help.html');
};

before '/index-help.html' => run {
    set 'getting_help' => 1;
};

1;
