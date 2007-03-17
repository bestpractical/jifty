use warnings;
use strict;

=head1 NAME

Jifty::Plugin::Authentication::Password::Action::ConfirmEmail - Confirm a user's email address

=head1 DESCRIPTION

This is the link in a user's email to confirm that their email
email is really theirs.  It is not really meant to be rendered on any
web page, but is used by the confirmation notification.

=cut

package Jifty::Plugin::Authentication::Password::Action::ConfirmEmail;
use base qw/Jifty::Action/;

=head2 arguments

A null sub, because the superclass wants to make sure we fill in arguments

=cut

sub arguments { }

=head2 take_action

Set their confirmed status.

=cut

sub take_action {
    my $self        = shift;
        my $LoginUser   = Jifty->app_class('Model', 'User');
                my $CurrentUser   = Jifty->app_class('CurrentUser');



    my $u = $LoginUser->new( current_user => $CurrentUser->superuser );
    $u->load_by_cols(id => Jifty->web->current_user->user_object->id );

    if ( $u->email_confirmed ) {
        $self->result->error( email => _("You have already confirmed your account.") );
        $self->result->success(1);    # but the action is still a success
        return 1;
    }

    my ($val,$msg)  = $u->set_email_confirmed('1')  ;

    unless ($val) {
        $self->result->error($msg); 
        return undef;
    }

    # Set up our login message
    $self->result->message( _("Welcome to %1, %2. " , Jifty->config->framework('ApplicationName') , $u->name) ." "
          . _(". Your email address has now been confirmed.") );

    # Actually do the login thing.
    Jifty->web->current_user( $CurrentUser->new( id => $u->id ) );
    return 1;
}

1;
