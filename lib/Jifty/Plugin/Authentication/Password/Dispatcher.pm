use strict;
use warnings;

package Jifty::Plugin::Authentication::Password::Dispatcher;
use Jifty::Dispatcher -base;

my ($self) = Jifty->find_plugin('Jifty::Plugin::Authentication::Password');

=head1 NAME

Jifty::Plugin::Authentication::Password::Dispatcher - password plugin dispatcher

=head1 DESCRIPTION

All the dispatcher rules jifty needs to support L<Jifty::Authentication::Password/>

=head1 RULES

=cut

before '*' => run {
    Jifty->api->hide( 'Signup' );
} unless $self->signup;

=head2 C<before logout>

Logout and return home.

See L<Jifty::Plugin::Authentication::Password::Action::Logout>.

=cut

before 'logout' => run {
    Jifty->web->new_action( class => 'Logout', moniker => 'logout')->run;
    redirect '/';
};

# Make sure tangents work 
# Before password reminders, login or signup, let's push the user off to the homepage if they're logged in

=head2 C<before *>

Setup the navigation menu for login or logout.

=cut

before '*' =>  run {
    if ( Jifty->web->current_user->id ) {
        logged_in_nav();
    } else {
        not_logged_in_nav();

    }

} if $self->nav_menu;

=head2 C<on qr/^(?:signup|lost_password)$/>

Redirect to home if logged.

Request a password reminder or signup for an account otherwise.

=cut

before qr'^/(?:signup|lost_password)$' => run {
    redirect('/') if ( Jifty->web->current_user->id );
    set 'next' => Jifty->web->request->continuation || Jifty::Continuation->new( request => Jifty::Request->new( path => "/login" ) );
};

=head2 C<on login>

Redirect to home if logged.

Show the login form otherwise.

=cut

before qr|^/(?:login)$| => run {
    redirect('/') if ( Jifty->web->current_user->id );
    set 'next' => Jifty->web->request->continuation || Jifty::Continuation->new( request => Jifty::Request->new( path => "/" ) );
};

=head2 C<before reset_lost_password>

Request a password reset.

=cut

before qr|(?:reset_lost_password)| => run {
    set 'next' => Jifty->web->request->continuation || Jifty::Continuation->new( request => Jifty::Request->new( path => "/" ) );
};
# Send a password reminder for a lost password

=head2 C<before passwordreminder>

Request a new password reminder to be sent by email.

See L<Jifty::Plugin::Authentication::Password::Action::SendPasswordReminder>.

=cut

before 'passwordreminder' => run {
    set 'action' => Jifty->web->new_action( class => 'SendPasswordReminder', moniker => 'password_reminder');
};


=head2 C<before signup>

Sign up for an account.

See L<Jifty::Plugin::Authentication::Password::Action::Signup>.

=cut

before 'signup' => run {
    set 'action' => Jifty->web->new_action( class => 'Signup');

};

=head2 C<before login>

Login to your account.

See L<Jifty::Plugin::Authentication::Password::Action::Login>.

=cut

before 'login' => run {
    set 'action' => Jifty->web->new_action( class => 'Login');
};

=head2 not_logged_in_nav

Adds the login and signup links to the navigation menu.

=cut

sub not_logged_in_nav {
    Jifty->web->navigation->child(
        'Login',
        link => Jifty->web->tangent(
            label => _('Login'),
            url   => '/login'
        ),
        sort_order => '999'
    );
    Jifty->web->navigation->child(
        'Signup',
        link => Jifty->web->tangent(
            label => _('Sign up'),
            url   => '/signup'
        ),
        sort_order => '950'
    );
}

=head2 logged_in_nav

Adds the logout link to the navigation menu.

=cut

sub logged_in_nav {
    Jifty->web->navigation->child(
        Logout  => label => _('Logout') =>
            url => '/logout',
        sort_order => '999'
    );

}

=head1 SEE ALSO

L<Jifty::Plugin::Authentication::Password>, L<Jifty::Plugin::Authentication::Password::View>

=head1 COPYRIGHT

Jifty is Copyright 2005-2010 Best Practical Solutions, LLC.
Jifty is distributed under the same terms as Perl itself.

=cut

1;
