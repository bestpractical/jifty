package Jifty::Plugin::OAuth::Dispatcher;
use warnings;
use strict;

use Jifty::Dispatcher -base;

use Net::OAuth::RequestTokenRequest;
use Net::OAuth::AccessTokenRequest;
use Net::OAuth::ProtectedResourceRequest;
use Crypt::OpenSSL::RSA;

on     POST '/oauth/request_token' => \&request_token;
before GET  '/oauth/authorize'     => \&authorize;
on     POST '/oauth/access_token'  => \&access_token;

=head2 abortmsg CODE, MSG

Helper function to abort with a debug message. Maybe should be factored into
the C<abort> procedure?

=cut

sub abortmsg {
    my ($code, $msg) = @_;
    Jifty->log->debug($msg) if defined($msg);
    abort($code || 400);
}

=head2 request_token

The consumer wants a request token

=cut

sub request_token {
    my @params = qw/consumer_key signature_method signature
                    timestamp nonce version/;
    set no_abort => 0;

    my %oauth_params  = get_parameters(@params);
    my $consumer      = get_consumer($oauth_params{consumer_key});
    my $signature_key = get_signature_key($oauth_params{signature_method}, $consumer);
    my ($ok, $msg) = $consumer->is_valid_request(@oauth_params{qw/timestamp nonce/});
    abortmsg(401, $msg) if !$ok;

    # Net::OAuth::Request will die hard if it doesn't get everything it wants
    my $request = eval { Net::OAuth::RequestTokenRequest->new(
        request_url     => Jifty->web->url(path => '/oauth/request_token'),
        request_method  => Jifty->handler->apache->method(),
        consumer_secret => $consumer->secret,
        signature_key   => $signature_key,

        map { $_ => $oauth_params{$_} } @params
    ) };

    abortmsg(400, "Unable to create RequestTokenRequest: $@") if $@ || !defined($request);

    # make sure the signature matches the rest of what the consumer gave us
    abortmsg(401, "Invalid signature (type: $oauth_params{signature_method}).") unless $request->verify;

    # ok, everything checks out. send them back a request token
    # at this point, the only things that could go wrong are:
    # 1) we've already seen this nonce and timestamp. possibly a replay attack,
    #    so we abort
    # 2) we tried a bunch of times to create a unique token but failed. abort
    #    because we don't have any other option

    my $token = Jifty::Plugin::OAuth::Model::RequestToken->new(current_user => Jifty::CurrentUser->superuser);

    ($ok, $msg) = eval {
        $token->create(consumer => $consumer);
    };

    abortmsg(401, "Unable to create a Request Token: " . $@ || $msg)
        if $@ || !$ok;

    $consumer->made_request(@oauth_params{qw/timestamp nonce/});
    set oauth_response => {
        oauth_token        => $token->token,
        oauth_token_secret => $token->secret
    };
    show 'oauth/response';
}

=head2 authorize

The user is authorizing (or denying) a consumer's request token

=cut

sub authorize {
    my @params = qw/token callback/;

    set no_abort => 1;
    my %oauth_params = get_parameters(@params);

    set callback => $oauth_params{callback};
    set consumer => 'Some application';
    del 'token';

    if ($oauth_params{token}) {
        my $request_token = Jifty::Plugin::OAuth::Model::RequestToken->new(current_user => Jifty::CurrentUser->superuser);
        $request_token->load_by_cols(token => $oauth_params{token}, authorized => 'f');

        if ($request_token->id) {
            set consumer => $request_token->consumer;
            set token    => $oauth_params{token};
        }
    }
}

=head2 access_token

The consumer is trying to trade a request token for an access token

=cut

sub access_token {
    my @params = qw/consumer_key signature_method signature
                    timestamp nonce token version/;
    set no_abort => 0;

    my %oauth_params  = get_parameters(@params);
    my $consumer      = get_consumer($oauth_params{consumer_key});
    my $signature_key = get_signature_key($oauth_params{signature_method}, $consumer);
    my ($ok, $msg) = $consumer->is_valid_request(@oauth_params{qw/timestamp nonce/});
    abortmsg(401, $msg) if !$ok;

    # is the request token they're using still valid?
    my $request_token = Jifty::Plugin::OAuth::Model::RequestToken->new(current_user => Jifty::CurrentUser->superuser);
    $request_token->load_by_cols(consumer => $consumer, token => $oauth_params{token});

    abortmsg(401, "No token found for consumer ".$consumer->name." with key $oauth_params{token}") unless $request_token->id;

    ($ok, $msg) = $request_token->can_trade_for_access_token;
    abortmsg(401, "Cannot trade request token for access token: $msg") if !$ok;

    # Net::OAuth::Request will die hard if it doesn't get everything it wants
    my $request = eval { Net::OAuth::AccessTokenRequest->new(
        request_url     => Jifty->web->url(path => '/oauth/access_token'),
        request_method  => Jifty->handler->apache->method(),
        consumer_secret => $consumer->secret,
        token_secret    => $request_token->secret,
        signature_key   => $signature_key,

        map { $_ => $oauth_params{$_} } @params
    ) };

    abortmsg(400, "Unable to create AccessTokenRequest: $@") if $@ || !defined($request);

    # make sure the signature matches the rest of what the consumer gave us
    abortmsg(401, "Invalid signature (type: $oauth_params{signature_method}).") unless $request->verify;

    my $token = Jifty::Plugin::OAuth::Model::AccessToken->new(current_user => Jifty::CurrentUser->superuser);

    ($ok, $msg) = eval {
        $token->create(consumer => $consumer,
                       auth_as  => $request_token->authorized_by);
    };

    abortmsg(401, "Unable to create an Access Token: " . $@ || $msg)
        if $@ || !defined($token) || !$ok;

    $consumer->made_request(@oauth_params{qw/timestamp nonce/});
    set oauth_response => {
        oauth_token        => $token->token,
        oauth_token_secret => $token->secret
    };
    show 'oauth/response';
}

=head2 get_consumer CONSUMER KEY

Helper function to load a consumer by consumer key. Will abort if the key
is unknown.

=cut

sub get_consumer {
    my $key = shift;
    my $consumer = Jifty::Plugin::OAuth::Model::Consumer->new(current_user => Jifty::CurrentUser->superuser);
    $consumer->load_by_cols(consumer_key => $key);
    abortmsg(401, "No known consumer with key $key") if !$consumer->id;
    return $consumer;
}

=head2 get_signature_key SIGNATURE METHOD, CONSUMER

Figures out the signature key for this consumer. Will abort if the signature
method is unsupported, or if the consumer lacks the prerequisites for this
signature method.

Will return C<undef> is the signature key is consumer independent, as is the
case for C<PLAINTEXT> and C<HMAC-SHA1>. C<RSA-SHA1> depends on the consumer
having the C<rsa_key> field.

=cut

{
    my %valid_signature_methods = map { $_ => 1 }
                                  qw/PLAINTEXT HMAC-SHA1 RSA-SHA1/;
    my %key_field = ('RSA-SHA1' => 'rsa_key');

    sub get_signature_key {
        my ($method, $consumer) = @_;
        if (!$valid_signature_methods{$method}) {
            abortmsg(400, "Unsupported signature method requested: $method");
        }

        my $field = $key_field{$method};

        # this MUST return undef if the signature method requires no prior key
        return undef if !defined($field);

        my $key = $consumer->$field;

        abortmsg(400, "Consumer does not have necessary field $field required for signature method $method")
            unless defined $key;

        if ($method eq 'RSA-SHA1') {
            $key = Crypt::OpenSSL::RSA->new_public_key($key);
        }

        return $key;
    }
}

=head2 get_parameters REQUIRED PARAMETERS

This will retrieve all the request paremeters. This gets parameters besides
the ones in the OAuth spec, because the signature is based on all such request
parameters.

Pass in by name all the OAuth-required parameters. Do not include the C<oauth_>
prefix.

The precedence of parameters, from highest priority to lowest priority, is:

=over 4

=item Authorization header

=item WWW-Authenticate header

=item POST parameters

=item GET parameters (aka URL's query string)

=back

=cut

sub get_parameters {
    my %p;

    # XXX: Check Authorization header
    # XXX: Check WWW-Authenticate header

    my %params = Jifty->handler->apache->params();
    for (@_) {
        $p{$_} = delete $params{"oauth_$_"}
            if !defined $p{$_};
    }

    $p{version} ||= '1.0';

    unless (get 'no_abort') {
        # check to see if there are any unsupported parameters
        while (my ($key, undef) = each %params) {
            abortmsg(400, "Unsupported parameter: $key")
                if $key =~ /^oauth_/;
        }

        # check to see if we're missing anything
        for (@_) {
            abortmsg(400, "Undefined required parameter: $_")
                if !defined($p{$_});
        }

        if ($p{timestamp} && $p{timestamp} !~ /^\d+$/) {
            abortmsg(400, "Malformed timestamp. Expected positive integer, got $p{timestamp}");
        }
    }

    return %p;
}

1;

