use strict;
use warnings;

package Jifty::Plugin::Authentication::Facebook;
use base qw/Jifty::Plugin/;

use WWW::Facebook::API;

=head1 NAME

Jifty::Plugin::Authentication::Facebook

=head2 DESCRIPTION

Provides standalone Facebook authentication for your Jifty application.
It adds the columns C<facebook_name>, C<facebook_uid>, C<facebook_session>,
and C<facebook_session_expires> to your User model.

=head1 SYNOPSIS

In your jifty config.yml under the C<framework> section:

    Plugins:
        - Authentication::Facebook:
            api_key: xxx
            secret: xxx

You may set any options which the C<new> method of L<WWW::Facebook::API>
understands.

In your User model, you'll need to include the line

    use Jifty::Plugin::Authentication::Facebook::Mixin::Model::User;

B<after> your schema definition (which may be empty).  You may also wish
to include

    sub _brief_description { 'facebook_name' }

To use the user's Facebook name as their description.

See L<Jifty::Plugin::Authentication::Facebook::View> for the provided templates
and L<Jifty::Plugin::Authentication::Facebook::Dispatcher> for the URLs handled.

=cut

our %CONFIG = ( );

=head2 init

=cut

sub init {
    my $self = shift;
    %CONFIG  = @_;
}

=head2 api

Generates a new L<WWW::Facebook::API> for the current user

=cut

sub api {
    my $self = shift;
    my $api  = WWW::Facebook::API->new( %CONFIG );
    
    if ( Jifty->web->current_user->id ) {
        my $user = Jifty->web->current_user->user_object;
        $api->session(
            uid     => $user->facebook_uid,
            key     => $user->facebook_session,
            expires => $user->facebook_session_expires
        ) if $user->facebook_uid;
    }

    return $api;
}

=head2 get_login_url

Gets the login URL, preserving continuations

=cut

sub get_login_url {
    my $self = shift;
    my $next = '/facebook/callback';
 
    if ( Jifty->web->request->continuation ) {
        $next .= '?J:C=' . Jifty->web->request->continuation->id;
    }
    return $self->api->get_login_url( next => $next );
}

=head2 get_link_url

Gets the login URL used for linking, preserving continuations

=cut

sub get_link_url {
    my $self = shift;
    my $next = '/facebook/callback_link';
 
    if ( Jifty->web->request->continuation ) {
        $next .= '?J:C=' . Jifty->web->request->continuation->id;
    }
    return $self->api->get_login_url( next => $next );
}

1;
