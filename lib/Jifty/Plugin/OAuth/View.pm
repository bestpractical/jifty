package Jifty::Plugin::OAuth::View;
use strict;
use warnings;

use Jifty::View::Declare -base;

=head1 NAME

Jifty::Plugin::OAuth::View - Views for OAuth-ey bits

=cut

=head2 oauth/response

Internal template. Do not use.

It returns OAuth parameters to the consumer in the HTTP response body.

=cut

template 'oauth/response' => sub {
    my $params = get 'oauth_response';
    if (ref($params) eq 'HASH') {
        outs_raw join '&',
                 map { sprintf '%s=%s',
                       map { Jifty->web->escape_uri($_) }
                       $_, $params->{$_}
                 } keys %$params;
    }
};

=head2 oauth

An OAuth description page very much geared towards Consumers, since they'll
most likely be the only ones visiting yourapp.com/oauth

=cut

template 'oauth' => page {
    p {
        b { a { attr { href => "http://oauth.net/" } "OAuth" } };
        outs " is an open protocol to allow secure authentication to users' private data."
    }

    p {
        "This application supports OAuth. If you'd like to access the private resources of users of this site, you must first establish a Consumer Key, Consumer Secret, and, if applicable, RSA public key with us. You can do so by contacting " . (Jifty->config->framework('AdminEmail')||'us') . ".";
    }

    p {
        "Once you have a Consumer Key and Consumer Secret, you may begin letting users grant you access to our site. The relevant URLs are:"
    }

    dl {
        dt {
            outs "Request a Request Token";
            dd { Jifty->web->url(path => '/oauth/request_token') }
        }
        dt {
            outs "Obtain user authorization for a Request Token";
            dd { Jifty->web->url(path => '/oauth/authorize') }
        }
        dt {
            outs "Exchange a Request Token for an Access Token";
            dd { Jifty->web->url(path => '/oauth/access_token') }
        }
    }

    p {
        my $restful = 0;
        for (@{ Jifty->config->framework('Plugins') }) {
            if (defined $_->{REST}) {
                $restful = 1;
                last;
            }
        }

        outs "While you have a valid access token, you may browse the site as the user normally does.";

        if ($restful) {
            outs " You may also use our REST interface. See ";
            a {
                attr { href => Jifty->web->url(path => '=/help') }
                Jifty->web->url(path => '=/help')
            }
        }
    }
};

=head2 oauth/authorize

This is the page that Users see when authorizing a request token. It renders
the "insert token here" textbox if the consumer didn't put the request token
in the GET query, and (always) renders Allow/Deny buttons.

=cut

template 'oauth/authorize' => page { title => 'Someone wants stuff!' }
content {
    show '/oauth/help';

    my $authorize = Jifty->web->new_action(
        moniker => 'authorize_request_token',
        class   => 'AuthorizeRequestToken',
    );

    Jifty->web->form->start();
    Jifty->web->form->next_page(url => "/oauth/authorized");

    outs $authorize->hidden(callback => get 'callback');

    # if the site put the token in the request, then use it
    # otherwise, prompt the user for it
    my %args;
    my $token = get 'token';
    if ($token) {
        $args{token} = $token;
    }
    else {
        $authorize->form_field('token')->render;
    }

    outs_raw($authorize->button(
        label => 'Allow',
        arguments => { %args, authorize => 'allow' },
    ));

    outs_raw($authorize->button(
        label => 'Deny',
        arguments => { %args, authorize => 'deny' },
    ));

    Jifty->web->form->end();
};

=head2 oauth/authorized

Displayed after the user authorizes or denies a request token. Uses a link
to the callback if provided, otherwise the site's URL.

=cut

template 'oauth/authorized' => page { title => 'XXX' }
content {
    my $result    = Jifty->web->response->result('authorize_request_token');
    my $callback  = $result->content('callback');
    my $token     = $result->content('token');
    my $token_obj = $result->content('token_obj');

    $callback ||= $token_obj->consumer->url;

    if (!$callback) {
        p { "Oops! " . $token_obj->consumer->name . " didn't tell us how to get you back to their service. If you do find your way back, you'll probably need this token: " . $token };
    }
    else {
        $callback .= ($callback =~ /\?/ ? '&' : '?')
                  .  'oauth_token='
                  .  $token;
        set consumer => $token_obj->consumer;

        p {
            outs 'To return to ';
            show 'oauth/consumer';
            outs ', ';
            hyperlink(
                label => 'click here',
                url   => $callback,
            );
            outs '.';
        };
    }
};

=head2 oauth/help

This provides a very, very layman description of OAuth for users

=cut

private template 'oauth/help' => sub {
    div {
        p {
            show '/oauth/consumer';
            outs ' is trying to access some of your data on this site. If you trust this application, you may grant it access. Note that access is read-only and will expire in one hour.';
        }
        p {
            "If you're at all uncomfortable with the idea of someone rifling through your things, click Deny."
        }
    }
};

=head2 oauth/consumer

Renders the consumer's name, and if available, its URL as a link.

=cut

private template 'oauth/consumer' => sub {
    my $consumer = (get 'consumer') || 'Some application';

    span {
        outs ref($consumer) ? $consumer->name : $consumer;
        if (ref($consumer) && $consumer->url) {
            outs ' <';
            a { attr { href => $consumer->url } $consumer->url };
            outs ' >';
        }
    }
};

1;

