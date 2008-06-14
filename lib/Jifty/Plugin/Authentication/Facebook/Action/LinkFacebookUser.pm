use warnings;
use strict;

=head1 NAME

Jifty::Plugin::Authentication::Facebook::Action::LinkFacebookUser - link facebook user to current user

=cut

package Jifty::Plugin::Authentication::Facebook::Action::LinkFacebookUser;
use base qw/Jifty::Action/;

=head1 ARGUMENTS

=head2 auth_token

=cut

use Jifty::Param::Schema;
use Jifty::Action schema {
    param auth_token =>
        type is 'text',
        is mandatory;
};

=head1 METHODS

=head2 take_action

Get the session key using the Facebook API.  Link to current user.

=cut

sub take_action {
    my $self     = shift;
    my ($plugin) = Jifty->find_plugin('Jifty::Plugin::Authentication::Facebook');
    my $api      = $plugin->api;

    if ( not Jifty->web->current_user->id ) {
        $self->result->error(_("You must be logged in to link your user to your Facebook account."));
        return;
    }

    # Get the session
    $api->auth->get_session( $self->argument_value('auth_token') );

    my $user = Jifty->web->current_user->user_object;

    my $name = $api->users->get_info(
        uids    => $api->session_uid,
        fields  => 'name'
    )->[0]{'name'};

    # Set data
    $user->__set( column => 'facebook_name', value => $name );
    $user->__set( column => 'facebook_uid',  value => $api->session_uid );
    $user->__set( column => 'facebook_session', value => $api->session_key );
    $user->__set( column => 'facebook_session_expires', value => $api->session_expires );

    # Success!
    $self->report_success;

    return 1;
}

=head2 report_success

=cut

sub report_success {
    my $self = shift;
    $self->result->message(_("Your account has been successfully linked to your Facebook user %1!", Jifty->web->current_user->user_object->facebook_name ));
}

1;
