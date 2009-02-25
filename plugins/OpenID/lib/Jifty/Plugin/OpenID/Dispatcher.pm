use strict;
use warnings;

package Jifty::Plugin::OpenID::Dispatcher;
use Jifty::Dispatcher -base;

=head1 NAME

Jifty::Plugin::OpenID::Dispatcher - Dispatcher for OpenID plugin

=head1 DESCRIPTION

Dispatcher for L<Jifty::Plugin::OpenID>.  Handles a lot of the work.

=cut

before qr'^/(?:openid/link)' => run {
    tangent('/openid/login') unless (Jifty->web->current_user->id)
};

before qr'^/openid/login' => run {
    Jifty->api->allow('AuthenticateOpenID');
    set action => Jifty->web->new_action(
        class   => 'AuthenticateOpenID',
        moniker => 'authenticateopenid'
    );
};

before qr'^/openid/verify' => run {
    Jifty->api->allow('VerifyOpenID');
    Jifty->web->request->add_action(
        class   => 'VerifyOpenID',
        moniker => 'verifyopenid'
    );
};

on 'openid/verify_and_link' => run {
    my $result = Jifty->web->response->result('verifyopenid');
    my $user   = Jifty->web->current_user;
    if ( defined $result and $result->success and $user->id ) {
        my $openid = $result->content('openid');
        my ( $ret, $msg ) = $user->user_object->validate_openid( $openid );

        if ( not $ret ) {
            $result->error(_("It looks like someone is already using that OpenID."));
            redirect '/openid/link';
        }
        else {
            $user->user_object->link_to_openid( $openid );
            $result->message(_("The OpenID '$openid' has been linked to your account."));
        }
    }
    redirect '/';
};

on 'openid/verify_and_login' => run {
    my $result = Jifty->web->response->result('verifyopenid');

    if ( defined $result and $result->success ) {
        my $openid = $result->content('openid');
        my $user = Jifty->app_class('CurrentUser')->new( openid => $openid );
        $Dispatcher->log->info("User Class: $user. OpenID: $openid");

        if ( $user->id ) {
            # Set up our login message
            $result->message( _("Welcome back, ") . $user->username . "." );

            # Actually do the signin thing.
            Jifty->web->current_user($user);
            Jifty->web->session->expires( undef );
            Jifty->web->session->set_cookie;

            if(Jifty->web->request->continuation) {
                Jifty->web->request->continuation->call;
            } else {
                redirect '/';
            }
        }
        else {
            # User needs to create account still
            Jifty->web->session->set( openid => $openid );
            $Dispatcher->log->info("got openid: $openid");
            my $nick = get('openid.sreg.nickname');
            if ( $nick ) {
                redirect( Jifty::Web::Form::Clickable->new( url => '/openid/create', parameters => { nickname => $nick, openid => $openid } ));
            }
            else {
                redirect( Jifty::Web::Form::Clickable->new( url => '/openid/create' ) );
            }
        }
    }
    else {
        if(Jifty->web->request->continuation) {
            Jifty->web->request->continuation->call;
        } else {
            redirect '/openid/login';
        }
    }
};

on 'openid/create' => run {
    if ( not Jifty->web->session->get('openid') ) {
        redirect '/';
    }

    set action => Jifty->web->new_action( class => 'CreateOpenIDUser', parameters => { openid => Jifty->web->session->get("openid") } );
    set 'next' => Jifty->web->request->continuation ||
                  Jifty::Continuation->new( request => Jifty::Request->new( path => "/" ) );
};

1;
