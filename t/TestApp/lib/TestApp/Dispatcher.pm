package TestApp::Dispatcher;
use Jifty::Dispatcher -base;

on '/dispatch/' => run {
    dispatch "/dispatch/basic";
};

on '/dispatch/show/' => run {
    dispatch "/dispatch/basic-show";
};


my $count = 0;

on '/dispatch/basic' => run {
    set count => $count++;
};

on '/dispatch/basic-show' => run {
    set count => $count++;
    show '/dispatch/basic-show';
};

1;
