package Jifty::Plugin::OAuth::View;
use strict;
use warnings;

use Jifty::View::Declare -base;

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

template 'oauth/authorize' => page { title => 'Someone wants stuff!' }
content {
    show '/oauth/help';

    my $authorize = Jifty->web->new_action(
        moniker => 'authorize_request_token',
        class   => 'AuthorizeRequestToken',
    );

    Jifty->web->form->start( call => get 'next' );

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

private template 'oauth/consumer' => sub {
    my $consumer = get 'consumer' || 'Some application';

    span {
        outs ref($consumer) ? $consumer->name : $consumer;
        if (ref($consumer) && $consumer->url) {
            outs ' (';
            a { attr { $consumer->url } $consumer->url };
            outs ')';
        }
    }
};

1;

