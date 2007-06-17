package Jifty::Plugin::OpenID::View;
use strict;
use warnings;
use Jifty::View::Declare -base;

=head1 NAME

Jifty::Plugin::OpenID::View

=head1 DESCRIPTION

The view class for L<Jifty::Plugin::OpenID>.  Provides login and create pages.

=cut

template 'openid/login' => page {
    { title is _ "Login with your OpenID" }
    my $action = get('action');

    div {
        unless ( Jifty->web->current_user->id ) {
            div {
                attr { id => 'openid-login' };
                outs(
                    p {
                        em {
                            _(  qq{If you have a Livejournal or other OpenID account, you don\'t even need to sign up. Just log in.}
                            );
                        }
                    }
                );
                form {
                    render_action($action);
                    form_submit(
                        label  => _("Go for it!"),
                        submit => $action
                    );
                }
            };
        }
        else {
            outs( _("You already logged in.") );
        }
    }
};

template 'openid/create' => page {
    title is 'Set your username';
    my ( $action, $next ) = get( 'action', 'next' );

    p {
        outs(
            _(  'We need you to set a username or quickly check the one associated with your OpenID. Your username is what other people will see when you ask questions or make suggestions'
            )
        );
    };
    p {
        outs(
            _(  'If the username provided conflicts with an existing username or contains invalid characters, you will have to give us a new one.'
            )
        );
    };
    Jifty->web->form->start( call => $next );
    render_param( $action, 'name', default_value => get('nickname') );
    form_submit( label => _('Continue'), submit => $action );
    Jifty->web->form->end;
};


1;
