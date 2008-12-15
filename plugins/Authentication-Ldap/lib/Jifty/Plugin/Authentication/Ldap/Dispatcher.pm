use strict;
use warnings;

package Jifty::Plugin::Authentication::Ldap::Dispatcher;
use Jifty::Dispatcher -base;

# Put any plugin-specific dispatcher rules here.

# whitelist safe actions to avoid cross-site scripting
before '*' => run { Jifty->api->allow('LDAPLogout') };

# Log out
before 'ldaplogout' => run {
    Jifty->web->request->add_action(
        class   => 'LDAPLogout',
        moniker => 'ldaplogout',
    );
};

on ldaplogout  => run {
        redirect '/';
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
