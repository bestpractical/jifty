#!/usr/bin/env perl
package TestApp::Plugin::OAuth::Test;
use strict;
use warnings;
use base qw/Jifty::Test/;

use MIME::Base64;
use Crypt::OpenSSL::RSA;
use Digest::HMAC_SHA1 'hmac_sha1';

our @EXPORT = qw($timestamp $url $mech $pubkey $seckey response_is sign get_latest_token);

sub setup {
    my $class = shift;
    $class->SUPER::setup;
    $class->export_to_level(1);
}

our $timestamp = 0;
our $url;
our $mech;
our $pubkey = slurp('t/id_rsa.pub');
our $seckey = slurp('t/id_rsa');

sub response_is {
    ++$timestamp;

    my %params = (
        oauth_timestamp        => $timestamp,
        oauth_nonce            => scalar(reverse $timestamp),
        oauth_signature_method => 'HMAC-SHA1',
        oauth_version          => '1.0',

        code                   => 400,
        testname               => "",
        method                 => 'POST',
        token_secret           => '',
        @_,
    );

    for (grep {!defined $params{$_}} keys %params) {
        delete $params{$_};
    }

    my $code            = delete $params{code};
    my $testname        = delete $params{testname} || "Response was $code";
    my $method          = delete $params{method};
    my $token_secret    = delete $params{token_secret};
    my $consumer_secret = delete $params{consumer_secret}
        or die "consumer_secret not passed to response_is!";

    $params{oauth_signature} ||= sign($method, $token_secret, $consumer_secret, %params);

    my $r;

    if ($method eq 'POST') {
        $r = $mech->post($url, [%params]);
    }
    else {
        my $query = join '&',
                    map { "$_=" . Jifty->web->escape_uri($params{$_}||'') }
                    keys %params;
        $r = $mech->get("$url?$query");
    }

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    main::is($r->code, $code, $testname);

    my $token = get_latest_token();
    if ($code == 200) {
        main::ok($token, "Successfully loaded a token object with token ".$token->token.".");
    }
    else {
        main::ok(!$token, "Did not get a token");
    }
}

sub sign {
    my ($method, $token_secret, $consumer_secret, %params) = @_;

    local $url = delete $params{url} || $url;

    my $key = delete $params{signature_key};
    my $sig_method = $params{oauth_signature_method} || delete $params{_signature_method};

    delete $params{oauth_signature};

    if ($sig_method eq 'PLAINTEXT') {
        my $signature = join '&',
                        map { Jifty->web->escape_uri($_||'') }
                            $consumer_secret,
                            $token_secret;
        return $signature;
    }

    my $normalized_request_parameters
        = join '&',
          map { "$_=" . Jifty->web->escape_uri($params{$_}||'') }
          sort keys %params;

    my $signature_base_string
        = join '&',
          map { Jifty->web->escape_uri($_||'') }
              uc($method),
              $url,
              $normalized_request_parameters,
              $consumer_secret,
              $token_secret;

    my $signature;

    if ($sig_method eq 'RSA-SHA1') {
        my $pubkey = Crypt::OpenSSL::RSA->new_private_key($key);
        $signature = encode_base64($pubkey->sign($signature_base_string), "");
    }
    elsif ($sig_method eq 'HMAC-SHA1') {
        my $key = join '&',
          map { Jifty->web->escape_uri($_||'') }
              $consumer_secret,
              $token_secret;
        my $hmac = Digest::HMAC_SHA1->new($key);
        $hmac->add($signature_base_string);
        $signature = $hmac->b64digest;
    }

    return ($signature, $signature_base_string, $normalized_request_parameters)
        if wantarray;
    return $signature;

}

sub slurp {
    no warnings 'once';
    my $file = shift;
    local $/;
    local @ARGV = $file;
    my $contents = scalar <>
        or die "Unable to slurp $file";
    return $contents;
}

sub get_latest_token {
    my $content = $mech->content;

    $content =~ s/\boauth_token=(\w+)//
        or return;
    my $token = $1;

    $content =~ s/\boauth_token_secret=(\w+)//
        or return;
    my $secret = $1;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    main::is($content, '&', "the output was exactly oauth_token=...&oauth_secret=...");

    my $package = 'Jifty::Plugin::OAuth::Model::';

    if ($mech->uri =~ /request_token/) {
        $package .= 'RequestToken';
    }
    elsif ($mech->uri =~ /request_token/) {
        $package .= 'AccessToken';
    }
    else {
        Jifty->log->error("Called get_latest_token, but I cannot grok the URI " . $mech->uri);
        return;
    }

    my $token_obj = $package->new(current_user => Jifty::CurrentUser->superuser);
    $token_obj->load_by_cols(token => $token);

    if (!$token_obj->id) {
        Jifty->log->error("Could not find a $package with token $token");
        return;
    }

    return $token_obj;
}

1;

