use warnings;
use strict;

=head1 NAME

Jifty::Plugin::Login::Action::Login

=cut

package Jifty::Plugin::Login::Action::Login;
use base qw/Jifty::Action Jifty::Plugin::Login/;

=head2 arguments

Return the email and password form fields

=cut

sub arguments {
    return (
        {
            email => {
                label          => 'Email address',
                mandatory      => 1,
                ajax_validates => 1,
            },

            password => {
                type      => 'password',
                label     => 'Password',
                mandatory => 1
            },
            remember => {
                type  => 'checkbox',
                label => 'Remember me?',
                hints =>
                  'If you want, your browser can remember your login for you',
                default => 0,
            }
        }
    );

}

=head2 validate_email ADDRESS

Makes sure that the email submitted is a legal email address and that there's a user in the database with it.


=cut

sub validate_email {
    my $self  = shift;
    my $email = shift;
    my $LoginUser = $self->LoginUserClass();
    my $CurrentUser = $self->CurrentUserClass();

    unless ( $email =~ /\S\@\S/ ) {
        return $self->validation_error(
            email => "That doesn't look like an email address." );
    }

    my $u = $LoginUser->new( current_user => $CurrentUser->superuser );
    $u->load_by_cols( email => $email );
    return $self->validation_error(
        email => 'No account has that email address.' )
      unless ( $u->id );

    return $self->validation_ok('email');
}

=head2 take_action

Actually check the user's password. If it's right, log them in.
Otherwise, throw an error.


=cut

sub take_action {
    my $self = shift;
    my $CurrentUser = $self->CurrentUserClass();

    my $user = $CurrentUser->new( email => $self->argument_value('email') );

    unless ( $user->id
        && $user->password_is( $self->argument_value('password') ) )
    {
        $self->result->error(
 q{You may have mistyped your email address or password. Give it another shot?}
        );
        return;
    }

    unless ( $user->user_object->email_confirmed ) {
        $self->result->error(q{You haven't confirmed your account yet.});
        return;
    }

    # Set up our login message
    $self->result->message( "Welcome back, " . $user->user_object->name . "." );

    # Actually do the signin thing.
    Jifty->web->current_user($user);
    Jifty->web->session->expires(
        $self->argument_value('remember') ? '+1y' : undef );
    Jifty->web->session->set_cookie;

    return 1;
}

1;
