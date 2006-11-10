use strict;
use warnings;

package Jifty::Plugin::Login::Dispatcher;
use Jifty::Dispatcher -base;

# Put any plugin-specific dispatcher rules here.

on 'chgpasswd' => run {
    redirect('/login') if (! Jifty->web->current_user->id );
    set 'action' =>
        Jifty->web->new_action(
        class => 'ChangePassword',
        moniker => 'chgpasswdbox'
    );

    set 'next' => Jifty->web->request->continuation
        || Jifty::Continuation->new(
        request => Jifty::Request->new( path => "/" ) );

};


# Sign up for an account
on 'signup' => run {
    redirect('/') if ( Jifty->web->current_user->id );
    set 'action' =>
        Jifty->web->new_action(
	    class => 'Signup',
	    moniker => 'signupbox'
	);

    set 'next' => Jifty->web->request->continuation
        || Jifty::Continuation->new(
        request => Jifty::Request->new( path => "/" ) );

};

# Login
on 'login' => run {
    set 'action' =>
        Jifty->web->new_action(
	    class => 'Login',
	    moniker => 'loginbox'
	);
    set 'next' => Jifty->web->request->continuation
        || Jifty::Continuation->new(
        request => Jifty::Request->new( path => "/" ) );
};

# Log out
before 'logout' => run {
    Jifty->web->request->add_action(
        class   => 'Logout',
        moniker => 'logout',
    );
};

## LetMes
before qr'^/let/(.*)' => run {
    my $let_me = Jifty::LetMe->new();
    $let_me->from_token($1);
    redirect '/error/let_me/invalid_token' unless $let_me->validate;

    Jifty->web->temporary_current_user($let_me->validated_current_user);

    my %args = %{$let_me->args};
    set $_ => $args{$_} for keys %args;
    set let_me => $let_me;
};

on qr'^/let/' => run {
    my $let_me = get 'let_me';
    show '/let/' . $let_me->path;
};

1;
