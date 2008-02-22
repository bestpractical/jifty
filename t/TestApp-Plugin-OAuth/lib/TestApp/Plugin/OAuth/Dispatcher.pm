package TestApp::Plugin::OAuth::Dispatcher;
use strict;
use warnings;
use Jifty::Dispatcher -base;

my @login_required = qw{
    oauth/authorize
    nuke/?
    =/?
};

my $login_required = join '|', map {"^$_"} @login_required;
$login_required = qr/($login_required)/;

before '**' => run {
    my $path = $1;
    if (!Jifty->web->current_user->user_object && $path =~ $login_required) {
        tangent '/login';
    }
};

1;

