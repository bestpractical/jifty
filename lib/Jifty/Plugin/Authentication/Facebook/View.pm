use warnings;
use strict;
package Jifty::Plugin::Authentication::Facebook::View;

use Jifty::View::Declare -base;

=head1 NAME

Jifty::Plugin::Authentication::Facebook::View

=head1 DESCRIPTION

Provides the Facebook login regions for L<Jifty::Plugin::Authentication::Facebook>

=cut

template 'facebook/login' => sub {
    my ($plugin) = Jifty->find_plugin('Jifty::Plugin::Authentication::Facebook');
    my $next     = '/facebook/callback';

    if ( Jifty->web->request->continuation ) {
        $next .= '?J:C=' . Jifty->web->request->continuation->id;
    }

    div {{ id is 'facebook_login' };
        span { _("Login to Facebook now to get started!") };
        a {{ href is $plugin->api->get_login_url( next => $next ) };
            img {{ src is 'http://static.ak.facebook.com/images/devsite/facebook_login.gif', border is '0' }};
        };
    };
};

1;
