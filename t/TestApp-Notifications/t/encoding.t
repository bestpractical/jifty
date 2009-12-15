#!/usr/bin/env perl
use warnings;
use strict;

use Jifty::Test::Dist tests => 4;
use TestApp::Notifications::Notification;

sub send_and_receive {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $body = shift;

    Jifty::Test->setup_mailbox;

    my $notification = TestApp::Notifications::Notification->new;
    $notification->body($body);

    $notification->send_one_message;

    my @emails = Jifty::Test->messages;
    Jifty::Test->teardown_mailbox;

    is(scalar @emails, 1, "Sent one notification email");
    return $emails[0]->body;
}

my $body = send_and_receive("Simple Latin-1");
is($body, "Simple Latin-1");

# XXX: should this be "All L\N{LATIN SMALL LETTER E WITH ACUTE}on's fault"
$body = send_and_receive("All L\x{c3}\x{a9}on's fault");

is($body, "All L\x{c3}\x{a9}on's fault", "proper encoding");

