package TestApp::Plugin::OAuth::Dispatcher;
use strict;
use warnings;
use Jifty::Dispatcher -base;

my @login_required = qw{
    oauth/authorize
};

my $login_required = join '|', map {"^$_"} @login_required;
$login_required = qr/$login_required/;

before '*' => run {
    if (Jifty->web->current_user->id) {
        my $top = Jifty->web->navigation;
        $top->child( _('Pick!')    => url => '/pick' );
        $top->child( _('Choices')  => url => '/choices' );
    }
    elsif ($1 =~ $login_required) {
        tangent 'login';
    }
};

1;

