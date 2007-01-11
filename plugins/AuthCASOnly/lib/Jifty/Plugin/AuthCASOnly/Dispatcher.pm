use strict;
use warnings;

package Jifty::Plugin::AuthCASOnly::Dispatcher;
use Jifty::Dispatcher -base;

# Put any plugin-specific dispatcher rules here.

before 'caslogin' => run {
 if (get('ticket')) {
    set 'action' =>
        Jifty->web->new_action(
        class => 'CASLogin',
        moniker => 'casloginbox',
	arguments => { ticket => get('ticket') },
	arguments => { redirect => get('redirect') },
    );
#    set 'next' => Jifty->web->request->continuation
#        || Jifty::Continuation->new(
#        request => Jifty::Request->new( path => "/" ) );
  };
};

# Log out
before 'caslogout' => run {
    Jifty->web->request->add_action(
        class   => 'CASLogout',
        moniker => 'caslogout',
    );
};


# Login
#on 'caslogin' => run {
#    set 'action' =>
#        Jifty->web->new_action(
#        class => 'CASLogin',
#        moniker => 'casloginbox'
#    );
#    set 'next' => Jifty->web->request->continuation
#        || Jifty::Continuation->new(
#        request => Jifty::Request->new( path => "/" ) );
#};


1;
