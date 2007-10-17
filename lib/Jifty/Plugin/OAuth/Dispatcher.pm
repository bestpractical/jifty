package Jifty::Plugin::OAuth::Dispatcher;
use warnings;
use strict;

use Jifty::Dispatcher -base;

my $request_token_url = '/oauth/request_token';
my $authorize_url     = '/oauth/authorize';
my $access_token_url  = '/oauth/access_token';

before POST $request_token_url => \&request_token;
before GET  $authorize_url     => \&authorize;
before POST $access_token_url  => \&access_token;

# a consumer wants a request token
sub request_token {
    set oauth_url => $request_token_url;
    my $headers = Jifty->web->handler->apache->headers_in();

    for my $necessary_header (map {"oauth_$_"}
                                  qw/consumer_key signature_method signature
                                     timestamp nonce/) {
        abort(400) if !defined $headers->{$necessary_header};
    }

}

# the user is authorizing (or denying) a consumer's request token
sub authorize {
    set oauth_url => $authorize_url;

}

# the consumer is trying to trade a request token for an access token
sub access_token {
    set oauth_url => $access_token_url;

}

# 9.1.1
sub get_normalized_parameters {
    my $parameters = Jifty->handler->apache->headers_in();
    my @parameters;

    # we can't just use a hash because parameters may be repeated
    $parameters->do(sub {
        my ($key, $value) = @_;
        push @parameters, [$key, defined($value) ? $value : ''];
        return 1;
    });

    # XXX: include query parameters (http://x.com/path?THIS=THAT)

    for (@parameters) {
        @$_ = map { Jifty->web->escape_uri($_) } @$_;
    }

    return join '&',
           map  { "$_->[0]=$_->[1]" }
           grep { $_->[0] ne 'oauth_signature' }
           sort { $a->[0] cmp $b->[0] || $a->[1] cmp $b->[1] } @parameters;
}

# 9.1.2
sub get_request_elements {
    my $method          = uc Jifty->handler->apache->method();
    my $url             = Jifty->web->url(get 'oauth_url');
    my $parameters      = get_normalized_parameters();
    my $consumer_secret = 'todo';
    my $token_secret    = 'todo' || '';
}

1;

