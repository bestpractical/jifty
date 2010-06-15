#!/usr/bin/env perl
use warnings;
use strict;

use Jifty::Test::Dist tests => 24;
use TestApp::Notification::Foo;

sub send_and_receive {
    Jifty::Test->setup_mailbox;

    my $notification = TestApp::Notification::Foo->new;
    $notification->send_one_message;

    my @emails = Jifty::Test->messages;
    Jifty::Test->teardown_mailbox;

    is(scalar @emails, 1, "Sent one notification email");
    return Email::MIME->new($emails[0]->as_string)->body_str . "\n";
}

# Normal, non-ssl with no request object
ok !Jifty->web->request, "no request object";
ok !Jifty->web->is_ssl, "is_ssl returns 0";
my $body = send_and_receive();
like $body, qr/^http:/, "Got http:// notification url for is_ssl = 0 with no request object";
like +Jifty->web->url(path => '/foo'), qr/^http:/, "Got http:// url as normal";

# Normal, non-ssl with an http request object
Jifty::Test->web;
ok +Jifty->web->request, "got request object";
ok !Jifty->web->is_ssl, "is_ssl returns 0";
$body = send_and_receive();
like $body, qr/^http:/, "Got http:// notification url for is_ssl = 0 with request object";
like +Jifty->web->url(path => '/foo'), qr/^http:/, "Got http:// url as normal";


# Override Jifty->web->is_ssl to always return true for this test
# to fake an HTTPS environment
{ no warnings 'redefine'; *Jifty::Web::is_ssl = sub { 1 }; }

#
# Normal, ssl indicated, but no request object
#
Jifty->web->request(undef);
ok !Jifty->web->request, "no request object";
ok +Jifty->web->is_ssl, "is_ssl returns 1";
$body = send_and_receive();
like $body, qr/^http:/, "Got http:// notification url for is_ssl = 1 with no request object";
like +Jifty->web->url(path => '/foo'), qr/^https:/, "Got https:// url as normal";


#
# Normal, ssl with an https request object
#
Jifty::Test->web;
my $req = Jifty->web->request;

# Fake https scheme for the request object
$req->scheme('https');
$req->uri->scheme('https');
$req->uri->host('localhost');

ok $req, "got request object";
is $req->scheme, 'https', "https scheme in request";
ok $req->uri, "got request->uri";
is $req->uri->scheme, 'https', "https scheme in request->uri";
ok $req->uri->host, "got request->uri->host";
ok +Jifty->web->is_ssl, "is_ssl returns 1";

$body = send_and_receive();
like $body, qr/^http:/, "Got http:// notification url for is_ssl = 1 with request object";
like +Jifty->web->url(path => '/foo'), qr/^https:/, "Got https:// url as normal";

