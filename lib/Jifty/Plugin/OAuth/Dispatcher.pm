package Jifty::Plugin::OAuth::Dispatcher;
use warnings;
use strict;

use Jifty::Dispatcher -base;

use Net::OAuth::RequestTokenRequest;
use Net::OAuth::AccessTokenRequest;
use Net::OAuth::ProtectedResourceRequest;

before POST '/oauth/request_token' => \&request_token;
before GET  '/oauth/authorize'     => \&authorize;
before POST '/oauth/access_token'  => \&access_token;

# helper function to abort with a debug message
sub abortmsg {
    my ($code, $msg) = @_;
    Jifty->log->error($msg) if defined($msg);
    abort($code || 400);
}

# a consumer wants a request token
sub request_token {
    my @params = qw/consumer_key signature_method signature
                    timestamp nonce version/;

    my %oauth_params = get_parameters(@params);
    validate_signature_method($oauth_params{signature_method});
    my $consumer = get_consumer($oauth_params{consumer_key});

    # Net::OAuth::Request will die hard if it doesn't get everything it wants
    my $request = eval { Net::OAuth::RequestTokenRequest->new(
        request_url     => Jifty->web->url(path => '/oauth/request_token'),
        request_method  => Jifty->handler->apache->method(),
        consumer_secret => $consumer->secret,

        map { $_ => $oauth_params{$_} } @params
    ) };

    abortmsg(400, "Unable to create RequestTokenRequest: $@") if $@ || !defined($request);

    # make sure the signature matches the rest of what the consumer gave us
    abortmsg(401, "Invalid signature.") unless $request->verify;

    # ok, everything checks out. send them back a request token
    # at this point, the only things that could go wrong are:
    # 1) we've already seen this nonce and timestamp. possibly a replay attack,
    #    so we abort
    # 2) we tried a bunch of times to create a unique token but failed. abort
    #    because we don't have any other option

    my $token = Jifty::Plugin::OAuth::Model::RequestToken->new(current_user => Jifty::CurrentUser->superuser);

    my ($ok, $msg) = eval {
        $token->create(nonce => $oauth_params{nonce}, time_stamp => $oauth_params{timestamp});
    };

    abortmsg(401, "Unable to create a Request Token: " . $@ || $msg)
        if $@ || !defined($token) || !$ok;

    # XXX: actually send the token
}

# the user is authorizing (or denying) a consumer's request token
sub authorize {
    my @params = qw/token callback/;

    set no_abort => 1;
    my %oauth_params = get_parameters(@params);

    set next => $oauth_params{callback};
    set consumer => 'Some application';

    if ($oauth_params{token}) {
        my $request_token = Jifty::Plugin::OAuth::Model::RequestToken->new(current_user => Jifty::CurrentUser->superuser);
        $request_token->load_by_cols(token => $oauth_params{token});

        if ($request_token->id) {
            set consumer => $request_token->consumer;
            set token    => $oauth_params{token};
        }
    }
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

    abortmsg(401, "No token found for consumer ".$consumer->name." with key $oauth_params{token}") unless $request_token->id;

    my ($ok, $msg) = $request_token->can_trade_for_access_token;
    abortmsg(401, "Cannot trade request token for access token: $msg") if !$ok;

    # Net::OAuth::Request will die hard if it doesn't get everything it wants
    my $request = eval { Net::OAuth::AccessTokenRequest->new(
        request_url     => Jifty->web->url(path => '/oauth/access_token'),
        request_method  => Jifty->handler->apache->method(),
        consumer_secret => $consumer->secret,
        token_secret    => $request_token->secret,

        map { $_ => $oauth_params{$_} } @params
    ) };

    abortmsg(400, "Unable to create AccessTokenRequest: $@") if $@ || !defined($request);

    # make sure the signature matches the rest of what the consumer gave us
    abortmsg(401, "Invalid signature.") unless $request->verify;

    my $token = Jifty::Plugin::OAuth::Model::AccessToken->new(current_user => Jifty::CurrentUser->superuser);

    ($ok, $msg) = eval {
        $token->create(consumer => $consumer,
                       auth_as => $request_token->authorized_by,
                       time_stamp => $oauth_params{timestamp},
                       nonce => $oauth_params{nonce});
    };

    abortmsg(401, "Unable to create an Access Token: " . $@ || $msg)
        if $@ || !defined($token) || !$ok;

    # XXX: actually send the token
}

sub get_consumer {
    my $key = shift;
    my $consumer = Jifty::Plugin::OAuth::Model::Consumer->new(current_user => Jifty::CurrentUser->superuser);
    $consumer->load_by_cols(consumer_key => $key);
    abortmsg(401, "No known consumer with key $key") if !$consumer->id;
    return $consumer;
}

my %valid_signature_methods = map { $_ => 1 } qw/PLAINTEXT HMAC-SHA1 RSA-SHA1/;
sub validate_signature_method {
    my $method = shift;
    return if $valid_signature_methods{$method};
    abortmsg(400, "Unsupported signature method requested: $method");
}

sub get_parameters {
    my %p;

    # XXX: Check Authorization header
    # XXX: Check WWW-Authenticate header

    my %params = Jifty->handler->apache->params();
    use Data::Dumper; warn Dumper \%params;
    @p{@_} = @params{map {"oauth_$_"} @_};

    $p{version} ||= '1.0';

    unless (get 'no_abort') {
        for (@_) {
            abortmsg(400, "Undefined required parameter: $_")
                if !defined($p{$_});
        }
    }

    return %p;
}

1;

