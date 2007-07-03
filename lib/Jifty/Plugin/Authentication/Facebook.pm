use strict;
use warnings;

package Jifty::Plugin::Authentication::Facebook;
use base qw/Jifty::Plugin/;

use WWW::Facebook::API;

=head1 NAME

Jifty::Plugin::Authentication::Facebook

=head1 SYNOPSIS

In your jifty config.yml under the C<framework> section:

    Plugins:
        - Authentication::Facebook:
            api_key: xxx
            secret: xxx

You may set any options which the C<new> method of
L<WWW::Facebook::API> understands.

=head2 DESCRIPTION

Provides Facebook authentication for your Jifty application.
It adds the columns C<facebook_name>, C<facebook_uid>, C<facebook_session>,
and C<facebook_session_expires> to your C<User> model class.

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

1;
