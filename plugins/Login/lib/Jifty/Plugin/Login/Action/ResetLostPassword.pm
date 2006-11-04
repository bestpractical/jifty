use warnings;
use strict;

=head1 NAME

Jifty::Plugin::Login::Action::ResetPassword - Confirm and reset a lost password

=head1 DESCRIPTION

This is the action run by the link in a user's email to confirm that their email
address is really theirs, when claiming that they lost their password.  


=cut

package Jifty::Plugin::Login::Action::ResetLostPassword;
use base qw/Jifty::Action Jifty::Plugin::Login/;

=head2 arguments

ConfirmEmail has the following fields: address, code, password, and password_confirm.
Note that it can get the first two from the confirm dhandler.

=cut

sub arguments {
    return (
        {
            password         => { type => 'password', sticky => 0 },
            password_confirm => {
                type   => 'password',
                sticky => 0,
                label  => _('type your password again')
            },
        }
    );
}

=head2 take_action

Resets the password.

=cut

sub take_action {
    my $self        = shift;
    my $LoginUser = $self->LoginUserClass();
    my $CurrentUser = $self->CurrentUserClass();
    my $u = $LoginUser->new( current_user => $CurrentUser->superuser );
    $u->load_by_cols( email => Jifty->web->current_user->user_object->email );

    unless ($u) {
        $self->result->error(
_("You don't exist. I'm not sure how this happened. Really, really sorry. Please email us!")
        );
    }

    my $pass   = $self->argument_value('password');
    my $pass_c = $self->argument_value('password_confirm');

    # Trying to set a password (ie, submitted the form)
    unless (defined $pass
        and defined $pass_c
        and length $pass
        and $pass eq $pass_c )
    {
        $self->result->error(
_("It looks like you didn't enter the same password into both boxes. Give it another shot?")
        );
        return;
    }

    unless ( $u->set_password($pass) ) {
        $self->result->error(_("There was an error setting your password."));
        return;
    }

    # Log in!
    $self->result->message(_("Your password has been reset.  Welcome back."));
    Jifty->web->current_user( $CurrentUser->new( id => $u->id ) );
    return 1;

}

1;
