package Jifty::Plugin::OAuth::Dispatcher;
use warnings;
use strict;

use Jifty::Dispatcher -base;

use Net::OAuth::RequestTokenRequest;
use Net::OAuth::AccessTokenRequest;
use Net::OAuth::ProtectedResourceRequest;
use Crypt::OpenSSL::RSA;
use URI::Escape 'uri_unescape';

on     POST '/oauth/request_token' => \&request_token;
before GET  '/oauth/authorize'     => \&authorize;
on     POST '/oauth/authorize'     => \&authorize_post;
on     POST '/oauth/access_token'  => \&access_token;
on          '/oauth/authorized'    => run { redirect '/oauth/authorize' };

on     GET  '/oauth/request_token' => \&invalid_method;
on     GET  '/oauth/access_token'  => \&invalid_method;

before '*' => \&try_oauth;

=head2 abortmsg CODE, MSG

Helper function to abort with a debug message. Maybe should be factored into
the C<abort> procedure?

=cut

sub abortmsg {
    my ($code, $msg) = @_;
    if ($code) {
        Jifty->log->debug("$code for ".Jifty->web->request->path.": $msg") if defined($msg);
        abort($code);
    }
    elsif (defined $msg) {
        Jifty->log->debug("OAuth denied for ".Jifty->web->request->path.": $msg");
    }
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
    abortmsg(403, "Cannot authorize tokens as an OAuthed user") if Jifty->web->current_user->is_oauthed;

    set no_abort => 1;
    my %oauth_params = get_parameters(@params);

    set callback => $oauth_params{callback};
    set consumer => 'Some application';
    del 'token';

    if ($oauth_params{token}) {
        my $request_token = Jifty::Plugin::OAuth::Model::RequestToken->new(current_user => Jifty::CurrentUser->superuser);
        $request_token->load_by_cols(token => $oauth_params{token}, authorized => 0);

        if ($request_token->id) {
            set consumer => $request_token->consumer;
            set token    => $oauth_params{token};
        }
    }
}

=head2 authorize_post

The user is submitting an AuthorizeRequestToken action

=cut

sub authorize_post {
    abortmsg(403, "Cannot authorize tokens as an OAuthed user") if Jifty->web->current_user->is_oauthed;
    my $result = Jifty->web->response->result("authorize_request_token");
    unless ($result && $result->success) {
        redirect '/oauth/authorize';
    }

    set result => $result;
    show '/oauth/authorized';
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

    my $token = Jifty::Plugin::OAuth::Model::AccessToken->create_from_request_token($request_token);

    abortmsg(401, "Unable to create an Access Token: " . $@ || $msg)
        if $@ || !defined($token) || !$ok;

    $consumer->made_request(@oauth_params{qw/timestamp nonce/});
    $request_token->set_used(1);

    set oauth_response => {
        oauth_token        => $token->token,
        oauth_token_secret => $token->secret
    };
    show 'oauth/response';
}

=head2 try_oauth

If this is a protected resource request, see if we can authorize the request
with an access token.

This is dissimilar to the other OAuth requests because if anything fails, you
just don't set a current_user, and then the rest of the dispatcher rules will
take care of it. Thus, failure is handled quite differently in this rule.  We
try to abort as early as possible to make OAuth less of a hit on all requests.

=cut

sub try_oauth
{
    my @params = qw/consumer_key signature_method signature
                    timestamp nonce token version/;
    set no_abort => 1;
    my %oauth_params = get_parameters(@params);
    for (@params) {
        abortmsg(undef, "Undefined required parameter: $_"), return if !defined($oauth_params{$_});
    }

    my $consumer = get_consumer($oauth_params{consumer_key});
    return if !$consumer->id;
    abortmsg(undef, "No known consumer with key $oauth_params{consumer_key}"), return unless $consumer->id;

    my $signature_key = get_signature_key($oauth_params{signature_method}, $consumer);
    if ($signature_key && ref($signature_key) && !defined($$signature_key)) {
        abortmsg(undef, "Failed to get signature key.");
        return;
    }

    my ($ok, $msg) = $consumer->is_valid_request(@oauth_params{qw/timestamp nonce/});
    abortmsg(undef, $msg), return if !$ok;

    my $access_token = Jifty::Plugin::OAuth::Model::AccessToken->new(current_user => Jifty::CurrentUser->superuser);
    $access_token->load_by_cols(consumer => $consumer, token => $oauth_params{token});

    abortmsg(undef, "No token found for consumer ".$consumer->name." with key $oauth_params{token}"), return unless $access_token->id;

    ($ok, $msg) = $access_token->is_valid;
    abortmsg(undef, "Cannot access protected resources with this access token: $msg"), return if !$ok;

    # Net::OAuth::Request will die hard if it doesn't get everything it wants
    my $request = eval { Net::OAuth::ProtectedResourceRequest->new(
        request_url     => Jifty->web->url(path => Jifty->web->request->path),
        request_method  => Jifty->handler->apache->method(),
        consumer_secret => $consumer->secret,
        token_secret    => $access_token->secret,
        signature_key   => $signature_key,

        map { $_ => $oauth_params{$_} } @params
    ) };

    abortmsg(undef, "Unable to create ProtectedResourceRequest: $@"), return if $@ || !defined($request);

    abortmsg(undef, "Invalid signature (type: $oauth_params{signature_method})."), return unless $request->verify;

    $consumer->made_request(@oauth_params{qw/timestamp nonce/});

    my $new_current_user = Jifty->app_class('CurrentUser')->new(
        id => $access_token->auth_as,
    );
    $new_current_user->is_oauthed(1);
    $new_current_user->oauth_token($access_token);

    Jifty->web->temporary_current_user($new_current_user);

    Jifty->log->info("Consumer " . $consumer->name . " successfully OAuthed as user ". $access_token->auth_as);
}

=head2 invalid_method

This aborts the request with an "invalid HTTP method" response code.

=cut

sub invalid_method {
    Jifty->web->response->add_header(Allow => 'POST');
    abort(405);
}

=head2 get_consumer CONSUMER KEY

Helper function to load a consumer by consumer key. Will abort if the key
is unknown.

=cut

sub get_consumer {
    my $key = shift;
    my $consumer = Jifty::Plugin::OAuth::Model::Consumer->new(current_user => Jifty::CurrentUser->superuser);
    $consumer->load_by_cols(consumer_key => $key);
    abortmsg(401, "No known consumer with key $key") unless $consumer->id || get 'no_abort';
    return $consumer;
}

=head2 get_signature_key SIGNATURE METHOD, CONSUMER

Figures out the signature key for this consumer. Will abort if the signature
method is unsupported, or if the consumer lacks the prerequisites for this
signature method.

Will return C<undef> if the signature key is consumer independent, as is the
case for C<PLAINTEXT> and C<HMAC-SHA1>. C<RSA-SHA1> depends on the consumer
having the C<rsa_key> field.

If the signature method is invalid and no_abort is set, it will return a
special value of a reference to undef. Yes this sucks but undef already has
an important meaning.

=cut

{
    my %valid_signature_methods = map { $_ => 1 }
                                  qw/PLAINTEXT HMAC-SHA1 RSA-SHA1/;
    my %key_field = ('RSA-SHA1' => 'rsa_key');

    sub get_signature_key {
        my ($method, $consumer) = @_;
        if (!$valid_signature_methods{$method}) {
            abortmsg(400, "Unsupported signature method requested: $method")
                unless get 'no_abort';
            return \undef;
        }

        my $field = $key_field{$method};

        # this MUST return undef if the signature method requires no prior key
        return undef if !defined($field);

        my $key = $consumer->$field;

        if (!defined $key) {
            abortmsg(400, "Consumer does not have necessary field $field required for signature method $method") unless get 'no_abort';
            return;
        }

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
    my %params = Jifty->handler->apache->params();

    # Check Authorization header
    my $authz = Jifty->handler->apache->header_in("Authorization");
    if ($authz && $authz =~ s/^\s*OAuth\s*//i) {
        while ($authz =~ m{\s*([%a-zA-Z0-9._~-]+)="([%a-zA-Z0-9._~-]*)"\s*}g) {
            $params{uri_unescape($1)} = uri_unescape($2);
        }
    }

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

