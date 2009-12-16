#!/usr/bin/env perl
use warnings;
use strict;

use Jifty::Test::Dist tests => 4;
use TestApp::Notifications::Notification;
use encoding 'utf8';

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

{
    my $str = "Simple Latin-1\n\n";  # latin bytes string
    utf8::encode( $str );  # upgrade $str to utf8 bytes string
    diag $str;
    my $body = send_and_receive( $str );
    is($body, $str );
}

# XXX: should this be "All L\N{LATIN SMALL LETTER E WITH ACUTE}on's fault"
{
    my $str = "All L\x{c3}\x{a9}on's fault\n\n";   # latin1 bytes string
    utf8::encode( $str );  # upgrade to utf8 bytes string
    diag $str;
    my $body = send_and_receive( $str );
    is($body, $str );
}
