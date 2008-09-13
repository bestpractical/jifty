use strict;
use warnings;

package Jifty::Plugin::Authentication::Ldap::Dispatcher;
use Jifty::Dispatcher -base;

# Put any plugin-specific dispatcher rules here.

# Log out
before 'ldaplogout' => run {
    Jifty->web->request->add_action(
        class   => 'LDAPLogout',
        moniker => 'ldaplogout',
    );
};


# Login
on 'ldaplogin' => run {
    set 'action' =>
        Jifty->web->new_action(
        class => 'LDAPLogin',
        moniker => 'ldaploginbox'
    );
    set 'next' => Jifty->web->request->continuation
        || Jifty::Continuation->new(
        request => Jifty::Request->new( path => "/" ) );
};



1;
