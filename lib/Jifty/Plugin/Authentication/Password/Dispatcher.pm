use strict;
use warnings;

package Jifty::Plugin::Authentication::Password::Dispatcher;
use Jifty::Dispatcher -base;

# Put any plugin-specific dispatcher rules here.

before 'logout' => run {
    Jifty->web->new_action( class => 'Logout', moniker => 'logout')->run;
    redirect '/';
};

# Make sure tangents work 
# Before password reminders, login or signup, let's push the user off to the homepage if they're logged in

before '*' =>  run {
    if ( Jifty->web->current_user->id ) {
        logged_in_nav();
    } else {
        not_logged_in_nav();

    }

};

on qr/^(?:passwordreminder|signup|login)$/ => run {
    redirect('/') if ( Jifty->web->current_user->id );
    set 'next' => Jifty->web->request->continuation || Jifty::Continuation->new( request => Jifty::Request->new( path => "/" ) );
};

# Send a password reminder for a lost password

on 'passwordreminder' => run {
    set 'action' => Jifty->web->new_action( class => 'SendPasswordReminder', moniker => 'password_reminder');
};

# Sign up for an account
on 'signup' => run {
    set 'action' => Jifty->web->new_action( class => 'Signup');

};

# Login
on 'login' => run {
    set 'action' => Jifty->web->new_action( class => 'Login');
};

sub not_logged_in_nav {
    Jifty->web->navigation->child(
        Login   => label => _('Login') =>
            url => '/login',
        sort_order => '999'
    );
    Jifty->web->navigation->child(
        Signup  => label => _('Sign up') =>
            url => '/signup',
        sort_order => '950'
    );
}

sub logged_in_nav {
    Jifty->web->navigation->child(
        Logout  => label => _('Logout') =>
            url => '/logout',
        sort_order => '999'
    );

}


1;
