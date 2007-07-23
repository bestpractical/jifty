use warnings;
use strict;

=head1 NAME

Jifty::Plugin::Authentication::Facebook::Action::LoginFacebookUser;

=cut

package Jifty::Plugin::Authentication::Facebook::Action::LoginFacebookUser;
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

Get the session key using the Facebook API.  Check for existing user.
If none, autocreate.  Login user.

=cut

sub take_action {
    my $self    = shift;
    my ($plugin)  = Jifty->find_plugin('Jifty::Plugin::Authentication::Facebook');
    my $api       = $plugin->api;

    # Get the session
    $api->auth->get_session( $self->argument_value('auth_token') );

    # Load up the user
    my $current_user = Jifty->app_class('CurrentUser');
    my $user = $current_user->new( facebook_uid => $api->session_uid );

    # Autocreate the user if necessary
    if ( not $user->id ) {
        my $action = Jifty->web->new_action(
            class           => 'CreateUser',
            current_user    => $current_user->superuser,
            arguments       => {
                facebook_uid     => $api->session_uid,
                facebook_session => $api->session_key,
                facebook_session_expires => $api->session_expires
            }
        );
        $action->run;

        if ( not $action->result->success ) {
            # Should this be less "friendly"?
            $self->result->error(_("Sorry, something weird happened (we couldn't create a user for you).  Try again later."));
            return;
        }

        $user = $current_user->new( facebook_uid => $api->session_uid );
    }

    my $name = $api->users->get_info(
        uids    => $api->session_uid,
        fields  => 'name'
    )->[0]{'name'};

    my $u = $user->user_object;

    # Always check name
    $u->__set( column => 'facebook_name', value => $name )
        if not defined $u->facebook_name or $u->facebook_name ne $name;

    # Update, just in case
    if ( $u->__value('facebook_session') ne $api->session_key ) {
        $u->__set( column => 'facebook_session', value => $api->session_key );
        $u->__set( column => 'facebook_session_expires', value => $api->session_expires );
    }

    # Login!
    Jifty->web->current_user( $user );
    Jifty->web->session->expires( (not $api->session_expires) ? '+1y' : undef );
    Jifty->web->session->set_cookie;

    # Success!
    $self->report_success;

    return 1;
}

=head2 report_success

=cut

sub report_success {
    my $self = shift;
    $self->result->message(_("Hi %1!", Jifty->web->current_user->user_object->facebook_name ));
}

1;
