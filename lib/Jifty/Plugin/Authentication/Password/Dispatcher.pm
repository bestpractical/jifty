use strict;
use warnings;

package Jifty::Plugin::Authentication::Password::Dispatcher;
use Jifty::Dispatcher -base;

# Put any plugin-specific dispatcher rules here.


=head1 NAME

Jifty::Plugin::Authentication::Password::Dispatcher

=head1 DESCRIPTION

All the dispatcher rules jifty needs to support L<Jifty::Authentication::Password/>

=cut


=head1 RULES


=head2 before logout

=cut

before 'logout' => run {
    Jifty->web->new_action( class => 'Logout', moniker => 'logout')->run;
    redirect '/';
};

# Make sure tangents work 
# Before password reminders, login or signup, let's push the user off to the homepage if they're logged in

=head2 before *

=cut

before '*' =>  run {
    if ( Jifty->web->current_user->id ) {
        logged_in_nav();
    } else {
        not_logged_in_nav();

    }

};

=head2 on qr/^(?:passwordreminder|signup)$/ 

=cut

on qr/^(?:passwordreminder|signup)$/ => run {
    redirect('/') if ( Jifty->web->current_user->id );
    set 'next' => Jifty->web->request->continuation || Jifty::Continuation->new( request => Jifty::Request->new( path => "/login" ) );
};

=head2 on login

=cut

on qr/^(?:login)$/ => run {
    redirect('/') if ( Jifty->web->current_user->id );
    set 'next' => Jifty->web->request->continuation || Jifty::Continuation->new( request => Jifty::Request->new( path => "/" ) );
};

# Send a password reminder for a lost password

=head2 on passwordreminder

=cut

on 'passwordreminder' => run {
    set 'action' => Jifty->web->new_action( class => 'SendPasswordReminder', moniker => 'password_reminder');
};


=head2 on signup

# Sign up for an account

=cut

on 'signup' => run {
    set 'action' => Jifty->web->new_action( class => 'Signup');

};

=head2 on login

Login

=cut

on 'login' => run {
    set 'action' => Jifty->web->new_action( class => 'Login');
};

=head2 not_logged_in_nav

=cut

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

=head2 logged_in_nav

=cut

sub logged_in_nav {
    Jifty->web->navigation->child(
        Logout  => label => _('Logout') =>
            url => '/logout',
        sort_order => '999'
    );

}


1;
