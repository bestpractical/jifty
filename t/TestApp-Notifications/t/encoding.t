#!/usr/bin/env perl
use warnings;
use strict;

use Jifty::Test::Dist tests => 4;
use TestApp::Notifications::Notification;
use charnames ':full';

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
    return Email::MIME->new($emails[0]->as_string)->body_str;
}

{
    my $str = "Simple Latin-1\n\n";  # latin bytes string
    my $body = send_and_receive( $str );
    is($body, $str );
}

{
    my $str = "All L\N{LATIN SMALL LETTER E WITH ACUTE}on's fault\n\n";
    my $body = send_and_receive( $str );
    is($body, $str );
}
