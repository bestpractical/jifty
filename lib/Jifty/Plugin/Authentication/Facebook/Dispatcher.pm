use strict;
use warnings;

package Jifty::Plugin::Authentication::Facebook::Dispatcher;
use Jifty::Dispatcher -base;

=head1 NAME

Jifty::Plugin::Authentication::Facebook::Dispatcher

=head1 DESCRIPTION

All the dispatcher rules jifty needs to support L<Jifty::Authentication::Facebook>

=head1 RULES

=head2 before '/facebook/callback'

=cut

before '/facebook/callback' => run {
    Jifty->web->request->add_action(
        moniker   => 'facebooklogin',
        class     => 'LoginFacebookUser',
        arguments => {
            auth_token => get('auth_token'),
        }
    );
    if ( Jifty->web->request->continuation ) {
        Jifty->web->request->continuation->call;
    }
    else {
        redirect '/';
    }
};

=head2 before '/facebook/logout'

=cut

before '/facebook/logout' => run {
    if ( Jifty->web->current_user->id ) {
        Jifty->web->current_user( undef );
        my ($plugin) = Jifty->find_plugin('Jifty::Plugin::Authentication::Facebook');
        $plugin->api->auth->logout;
    };
    redirect '/';
};

1;
