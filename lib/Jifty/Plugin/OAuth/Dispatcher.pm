package Jifty::Plugin::OAuth::Dispatcher;
use warnings;
use strict;

use Jifty::Dispatcher -base;

use Net::OAuth::RequestTokenRequest;
use Net::OAuth::AccessTokenRequest;
use Net::OAuth::ProtectedResourceRequest;

before POST $Jifty::Plugin::OAuth::CONFIG{request_token} => \&request_token;
before GET  $Jifty::Plugin::OAuth::CONFIG{authorize}     => \&authorize;
before POST $Jifty::Plugin::OAuth::CONFIG{access_token}  => \&access_token;

# a consumer wants a request token
sub request_token {
    my @params = qw/consumer_key signature_method signature
                    timestamp nonce version/;

    my %oauth_params = get_parameters(@params);
    validate_signature_method($oauth_params{signature_method});
    my $consumer = get_consumer($oauth_params{consumer_key});

    # Net::OAuth::Request will die hard if it doesn't get everything it wants
    my $request = eval { Net::OAuth::RequestTokenRequest->new(
        request_url     => Jifty->web->url(path => $Jifty::Plugin::OAuth::CONFIG{request_token}),
        request_method  => Jifty->handler->apache->method(),
        consumer_secret => $consumer->secret,

        map { $_ => $oauth_params{$_} } @params
    ) };

    abort(400) if $@ || !defined($request);

    # make sure the signature matches the rest of what the consumer gave us
    abort(401) unless $request->verify;

    # ok, everything checks out. send them back a request token
    # at this point, the only things that could go wrong are:
    # 1) we've already seen this nonce and timestamp. possibly a replay attack,
    #    so we abort
    # 2) we tried a bunch of times to create a unique token but failed. abort
    #    because we don't have any other option

    my $token = Jifty::Plugin::OAuth::Model::RequestToken->new(current_user => Jifty::CurrentUser->superuser);

    my ($ok) = eval {
        $token->create(map { $_ => $oauth_params{$_} } qw/timestamp nonce/);
    };

    abort(401) if $@ || !defined($token) || !$ok;

    # XXX: actually send the token
}

# the user is authorizing (or denying) a consumer's request token
sub authorize {
    my @params = qw/token callback/;

    set no_abort => 1;
    my %oauth_params = get_parameters(@params);

    set next => $oauth_params{callback};

    if ($oauth_params{token}) {
        my $request_token = Jifty::Plugin::OAuth::Model::RequestToken->new(current_user => Jifty::CurrentUser->superuser);
        $request_token->load_by_cols(token => $oauth_params{token});

        if ($request_token->id) {
            set consumer => $request_token->consumer;
            set token    => $oauth_params{token};
        }
    }

    default consumer => 'Some application';
}

# the consumer is trying to trade a request token for an access token
sub access_token {
    my @params = qw/consumer_key signature_method signature
                    timestamp nonce token version/;

    my %oauth_params = get_parameters(@params);
    validate_signature_method($oauth_params{signature_method});
    my $consumer = get_consumer($oauth_params{consumer_key});

    # is the request token they're using still valid?
    my $request_token = Jifty::Plugin::OAuth::Model::RequestToken->new(current_user => Jifty::CurrentUser->superuser);
    $request_token->load_by_cols(consumer => $consumer, token => $oauth_params{token});
    abort(401) unless $request_token->id;
    abort(401) unless $request_token->can_trade_for_access_token;

    # Net::OAuth::Request will die hard if it doesn't get everything it wants
    my $request = eval { Net::OAuth::AccessTokenRequest->new(
        request_url     => Jifty->web->url(path => $Jifty::Plugin::OAuth::CONFIG{access_token}),
        request_method  => Jifty->handler->apache->method(),
        consumer_secret => $consumer->secret,
        token_secret    => $request_token->secret,

        map { $_ => $oauth_params{$_} } @params
    ) };

    abort(400) if $@ || !defined($request);

    # make sure the signature matches the rest of what the consumer gave us
    abort(401) unless $request->verify;

    my $token = Jifty::Plugin::OAuth::Model::AccessToken->new(current_user => Jifty::CurrentUser->superuser);

    my ($ok) = eval {
        $token->create(consumer => $consumer,
                       user => $request_token->authorized_by,
                       map { $_ => $oauth_params{$_} } qw/timestamp nonce/);
    };

    abort(401) if $@ || !defined($token) || !$ok;

    # XXX: actually send the token
}

sub get_consumer {
    my $key = shift;
    my $consumer = Jifty::Plugin::OAuth::Model::Consumer->new(current_user => Jifty::CurrentUser->superuser);
    $consumer->load_by_cols(key => $key);
    abort(401) if !$consumer->id;
    return $consumer;
}

my %valid_signature_methods = map { $_ => 1 } qw/PLAINTEXT HMAC-SHA1 RSA-SHA1/;
sub validate_signature_method {
    my $method = shift;
    abort(400) unless $valid_signature_methods{$method};
}

sub get_parameters {
    my %p;

    # XXX: Check Authorization header
    # XXX: Check WWW-Authenticate header

    %p = ((map {
        my $v = Jifty->handler->apache->header_in("oauth_$_");
        defined $v ? ($_ => $v) : ()
    } @_), %p);

    # XXX: Check query string

    $p{version} ||= '1.0';

    unless (get 'no_abort') {
        abort(400) if grep { !defined($p{$_}) } @_
    }

    return %p;
}

1;

