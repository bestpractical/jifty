#!/usr/bin/env perl
use warnings;
use strict;
use utf8;
use Jifty::Test::Dist tests => 2;
use TestApp::Notifications::Notification;

sub send_and_receive {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $body = shift;

    Jifty::Test->setup_mailbox;

    my $notification = TestApp::Notifications::Notification->new;
    $notification->body($body);

    $notification->send_one_message;

    my @emails = Jifty::Test->messages;
    use Data::Dumper; warn Dumper( \@emails  );
    Jifty::Test->teardown_mailbox;

    is(scalar @emails, 1, "Sent one notification email");
    return $emails[0]->body;
}

my $body = send_and_receive("中文");
is($body, "中文");
