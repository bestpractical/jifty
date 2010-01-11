use warnings;
use strict;

=head1 NAME

Jifty::Plugin::Authentication::Password::Action::ResetPassword - Confirm and reset a lost password

=head1 DESCRIPTION

This is the action run by the link in a user's email to confirm that their email
address is really theirs, when claiming that they lost their password.  


=cut

package Jifty::Plugin::Authentication::Password::Action::ResetLostPassword;
use base qw/Jifty::Action/;

=head2 arguments

ConfirmEmail has the following fields: address, code, password, and password_confirm.
Note that it can get the first two from the confirm dhandler.

=cut

sub class_arguments {
    return (
        {
            password         => { 
                type => 'password', 
                sticky => 0, 
                label  => _('Password') 
            },
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
    my $LoginUser   = Jifty->app_class('Model', 'User');
        my $CurrentUser   = Jifty->app_class('CurrentUser');




    my $u = $LoginUser->new( current_user => $CurrentUser->superuser );
    $u->load_by_cols( email => Jifty->web->current_user->user_object->email );

    unless ($u) {
        $self->result->error(
            join( ' ',
                _("You don't exist."),
                _("I'm not sure how this happened."),
                _("Really, really sorry."),
                _("Please email us!") )
        );
    }

    my $pass   = $self->argument_value('password');
    my $pass_c = $self->argument_value('password_confirm');

    # Trying to set a password (ie, submitted the form)
    unless (defined $pass and defined $pass_c and length $pass and $pass eq $pass_c ) {
        $self->result->error( _("It looks like you didn't enter the same password into both boxes. Give it another shot?")
        );
        return;
    }

    unless ( $u->set_password($pass) ) {
        $self->result->error(_("There was an error setting your password."));
        return;
    }

    $u->set_email_confirmed('1');
    # Log in!
    $self->result->message(_("Your password has been reset.  Welcome back."));
    Jifty->web->current_user( $CurrentUser->new( id => $u->id ) );
    return 1;

}

1;
