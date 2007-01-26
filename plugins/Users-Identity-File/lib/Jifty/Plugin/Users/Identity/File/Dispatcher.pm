use strict;
use warnings;

package Jifty::Plugin::Users::Identity::File::Dispatcher;
use Jifty::Dispatcher -base;

# Put any plugin-specific dispatcher rules here.

# Login
on 'login' => run {
    set 'action' =>
        Jifty->web->new_action(
        class => 'Login',  #File login
        moniker => 'fileloginbox'
    );
    set 'next' => Jifty->web->request->continuation
        || Jifty::Continuation->new(
        request => Jifty::Request->new( path => "/" ) );
};

1;
