#!/usr/bin/env perl

use warnings;
use strict;
use Plack::Test;

=head1 DESCRIPTION

Tests that URLs constructed with Jifty->web->url are correct

=cut

use Jifty::Test tests => 5;

like(Jifty->web->url, qr{^http://localhost:\d+/$}, 'basic call works');
like(Jifty->web->url(path => 'foo/bar'), qr{^http://localhost:\d+/foo/bar$}, 'path works');
like(Jifty->web->url(path => '/foo/bar'), qr{^http://localhost:\d+/foo/bar$}, 'path with leading slash works');

Jifty::Handler->add_trigger(
    have_request => sub {
        is(Jifty->web->url, 'http://example.com/', 'setting hostname via request works');
        is(Jifty->web->url(path => 'foo/bar'), 'http://example.com/foo/bar', 'hostname via requestand path works');
    });

test_psgi
    app => Jifty->handler->psgi_app,
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => "http://example.com/foo/bar");
        my $res = $cb->($req);
    };
