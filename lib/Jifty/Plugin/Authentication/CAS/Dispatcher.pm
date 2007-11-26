use strict;
use warnings;

package Jifty::Plugin::Authentication::CAS::Dispatcher;
use Jifty::Dispatcher -base;

# Put any plugin-specific dispatcher rules here.

before '/caslogin' => run {
 if (get('ticket')) {
    # verify ticket 
    set 'action' =>
        Jifty->web->new_action(
        class => 'CASLogin',
        moniker => 'casloginbox',
        arguments => { ticket => get('ticket') },
        );


  };

  set 'next' => Jifty->web->request->continuation
      || Jifty::Continuation->new(
      request => Jifty::Request->new( path => "/" ) );

};


on '/caslogin' => run {

   Jifty->web->new_action(
       moniker => 'casloginbox',
       class   => 'CASLogin',
       arguments => { ticket => get('ticket') }
       )->run;

    if(Jifty->web->request->continuation) {
        Jifty->web->request->continuation->call;
     } else {
           redirect '/';
     }
};

# Log out
before '/caslogout' => run {
    Jifty->web->request->add_action(
        class   => 'CASLogout',
        moniker => 'caslogout',
    );
};

on '/caslogout' => run {
   redirect '/';
};

1;
