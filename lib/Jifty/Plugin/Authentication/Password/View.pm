use warnings;
use strict;

=head1 NAME

Jifty::Plugin::Authentication::Password::View - views for password plugin

=head1 DESCRIPTION

This provides the templates for the pages and forms used by the
password authentication plugin.

=cut

package Jifty::Plugin::Authentication::Password::View;
use Jifty::View::Declare -base;

my ($self) = Jifty->find_plugin('Jifty::Plugin::Authentication::Password');

=head1 TEMPLATES

=head2 signup

Displays a sign-up form.

=cut

if ($self->signup) {
    template 'signup' => page { title => _('Sign up') } content {
        show 'signup_widget';
    };

    template 'signup_widget' => sub {
        my ( $action, $next ) = get(qw(action next));
        $action ||= new_action( class => 'Signup' );
        $next ||= Jifty::Continuation->new( request => Jifty::Request->new(path => "/") );
        Jifty->web->form->start( call => $next );
        render_param( $action => 'name' , focus => 1);
        render_param( $action => $_ ) for ( grep {$_ ne 'name'} $action->argument_names );
        form_return( label => _('Sign up'), submit => $action );
        Jifty->web->form->end();
    };
}

=head2 login

Displays the login form.

=cut

template login => page { title => _('Login!') } content {
    show('/login_widget');
};

=head2 login_widget

A handy template for embedding the login form. Just include it in your templates via:

  show('/login_widget');

See L<Jifty::Plugin::Authentication::Password::Action::Login>.

=cut

template login_widget => sub {

    my ( $action, $next ) = get( 'action', 'next' );
    $action ||= new_action( class => 'Login' );
    my $moniker = $action->moniker;
    $next ||= Jifty::Continuation->new(
        request => Jifty::Request->new( path => "/" ) );
    unless ( Jifty->web->current_user->id ) {
        p {{ class is 'signup-pointer' };
            outs( _( "No account yet? It's quick and easy. " ));
            tangent( label => _("Sign up for an account!"), url   => '/signup');
        };
        h3  { _('Login with a password') };
        div {
            attr { id => 'jifty-login' };
            Jifty->web->form->start( call => $next );
            if ($action->login_by eq 'username' ) {
                render_param( $action, 'username', focus => 1 );
              } else {
                render_param( $action, 'email', focus => 1 );
              };
            render_param( $action, $_ ) for (qw(password remember token hashed_password));
            form_return(
                label   => _(q{Login}),
                submit  => $action,
                onclick => "return getPasswordToken('$moniker');"
            );
            hyperlink(
                label => _("Lost your password?"),
                url   => "/lost_password"
            );
            Jifty->web->form->end();
        };
    } else {
        outs( _("You're already logged in.") );
    }
};

=head2 let/reset_lost_password

After requesting a password reset and clicking on the link sent by email, this receives that click and provides the form for resetting the password.

See L<Jifty::Plugin::Authentication::Action::ResetLostPassword>.

=cut

template 'let/reset_lost_password' => page { title => _('Reset lost password') } content {
    my ( $next ) = get(qw(next));
    my $action = Jifty->web->new_action( class => 'ResetLostPassword' );

    Jifty->web->form->start( call => $next );
        render_param( $action => $_ ) for ( $action->argument_names );
        form_return( label => _("New password"), submit => $action );
    Jifty->web->form->end();
};

=head2 lost_password

Starts the process of sending a link to reset a lost password by email.

See L<Jifty::Plugin::Authentication::Password::SendPasswordReminder>.

=cut

template 'lost_password' => page { title => 'Send a link to reset your password' } content {
    my ( $next ) = get(qw(next));
    my $action = Jifty->web->new_action(
        moniker => 'password_reminder',
        class   => 'SendPasswordReminder',
    );

    outs( _(  "You lost your password. A link to reset it will be sent to the following email address:"));
    my $focused = 0;
    Jifty->web->form->start( call => $next );
        render_param( $action => $_, focus => $focused++ ? 0 : 1 ) for ( $action->argument_names );
            form_return( label => _(q{Send}), submit => $action);
    Jifty->web->form->end;

};

=head2 let/confirm_email

Handles the work of confirming an email address for a new account.

See L<Jifty::Plugin::Authenticaiton::Password::View>.

=cut

template 'let/confirm_email' => sub {
    new_action( class => 'ConfirmEmail' )->run;
    redirect("/");
};

=head2 resend_confirmation

Request a new email confirmation message be sent to your email account.

See L<Jifty::Plugin::Authentication::Password::Action::ResendConfirmation>.

=cut

template 'resend_confirmation' => page { title => 'Resend Confirmation Email' } content {
    my $resend = Jifty->web->new_action(
        class   => 'ResendConfirmation',
        moniker => 'resendconf'
    );

    if (    Jifty->web->current_user->id
        and Jifty->web->current_user->user_object->email_confirmed )
    {
        Jifty->web->redirect('/');
    } else {
        div {
            attr { id => 'overview' };
            form {
                Jifty->web->form->next_page( url => '/' );

                p {
                    _(  q{Fill in your address below, and we'll send out another confirmation email to you. }
                    );
                    render_param( $resend => 'email', focus => 1 );
                    form_submit( label => 'Resend Confirmation' );
                    }
                }
            }

    }
};

=head1 SEE ALSO

L<Jifty::Plugin::Authentication::Password>, L<Jifty::Plugin::Authentication::Password::Dispatcher>

=head1 LICENSE

Jifty is Copyright 2005-2010 Best Practical Solutions, LLC.
Jifty is distributed under the same terms as Perl itself.

=cut


1;
