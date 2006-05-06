package TestApp::Dispatcher;
use Jifty::Dispatcher -base;

before '/redirect' => run {
    Jifty->web->request->add_action(
        moniker => 'thing',
        class   => 'DoSomething',
    );
    redirect '/index.html';
};



on '/dispatch/' => run {
    dispatch "/dispatch/basic";
};

on '/dispatch/show/' => run {
    dispatch "/dispatch/basic-show";
};


my $count = 0;
my $before = 0;
my $after = 0;
my $after_once = 0;

on '/dispatch/basic' => run {
    set count => $count++;
};

on '/dispatch/basic-show' => run {
    set count => $count++;
    show '/dispatch/basic-show';
};

before '/dispatch/*' => run {
    set before     => $before++;
    set after      => $after;
    set after_once => $after_once;
};

after '/dispatch/*' => run {
    return if already_run;
    $after_once++;
};

after '/dispatch/*' => run {
    $after++;
};

1;
