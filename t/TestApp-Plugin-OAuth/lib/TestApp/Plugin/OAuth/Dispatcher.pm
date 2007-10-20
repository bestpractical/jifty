package TestApp::Plugin::OAuth::Dispatcher;
use strict;
use warnings;
use Jifty::Dispatcher -base;

my @always_allowed = qw{
    login
    signup
    oauth/request_token
    oauth/access_token
};
my $always_allowed = join '|', map {"^$_"} @always_allowed;
$always_allowed = qr/$always_allowed/;

before '*' => run {
    if (Jifty->web->current_user->id) {
        my $top = Jifty->web->navigation;
        $top->child( _('Pick!')    => url => '/pick' );
        $top->child( _('Choices')  => url => '/choices' );
    }
    elsif ($1 !~ $always_allowed) {
        tangent 'login';
    }
};

1;

