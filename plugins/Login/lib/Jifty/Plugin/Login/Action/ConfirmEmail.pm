use warnings;
use strict;

=head1 NAME

Jifty::Plugin::Login::Action::ConfirmEmail - Confirm a user's email address

=head1 DESCRIPTION

This is the link in a user's email to confirm that their email
email is really theirs.  It is not really meant to be rendered on any
web page, but is used by the confirmation notification.

=cut

package Jifty::Plugin::Login::Action::ConfirmEmail;
use base qw/Jifty::Action Jifty::Plugin::Login/;

=head2 actions

A null sub, because the superclass wants to make sure we fill in actions

=cut

sub actions { }

=head2 take_action

Set their confirmed status.

=cut

sub take_action {
    my $self        = shift;
    my $LoginUserClass   = $self->LoginUserClass;
    my $CurrentUser = $self->CurrentUserClass;
    my $u = $LoginUserClass->new( current_user => $CurrentUser->superuser );
    $u->load_by_cols( email => Jifty->web->current_user->user_object->email );

    if ( $u->email_confirmed ) {
        $self->result->error(
            email => _("You have already confirmed your account.") );
        $self->result->success(1);    # but the action is still a success
    }

    $u->set_email_confirmed('1');

    # Set up our login message
    $self->result->message( "Welcome to "
          . Jifty->config->framework('ApplicationName') . ", "
          . $u->name
          . _(". Your email address has now been confirmed.") );

    # Actually do the login thing.
    Jifty->web->current_user( $CurrentUser->new( id => $u->id ) );
    return 1;
}

1;
