use warnings;
use strict;

=head1 NAME

Jifty::Plugin::Authentication::PasswordAction::GeneratePasswordToken

=cut

package Jifty::Plugin::Authentication::PasswordAction::GeneratePasswordToken;
use base qw/Jifty::Action/;

=head2 arguments

We need the username of the user we're fetching a token for, so we can
return the salt.

=cut

sub arguments { 
    return( { username => { mandatory => 1 } });

}


=head2 take_action

Generate a token and throw it back to the browser.  Also, return the
user's password salt in $self->result->content.


=cut

sub take_action {
    my $self = shift;

    my $username = $self->argument_value('username');
    my $class = Jifty->app_class('Model','User');
    my $user = $class->new(current_user => Jifty::CurrentUser->superuser);
    $user->load_by_cols(username => $username);
    unless($user->id) {
        $self->result->error('No such user');
    }

    my $password = $user->_value('password');
    
    my $token = time();
    $self->result->content(token => $token);
    $self->result->content(salt  => ($password ? $password->[1] : ""));
    Jifty->web->session->set(login_token => $token);
}

1;
