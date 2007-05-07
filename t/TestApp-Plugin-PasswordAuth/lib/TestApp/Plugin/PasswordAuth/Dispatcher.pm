package TestApp::Plugin::PasswordAuth::Dispatcher;
use Jifty::Dispatcher -base;

on qr{/setuser/(.*)} => run {
    my $name = $1;

    my $current_user = TestApp::Plugin::PasswordAuth::CurrentUser->new( name => $name );
    Jifty->web->current_user( $current_user );
    show '/index.html';
};

1;
