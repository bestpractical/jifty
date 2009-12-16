#!/usr/bin/env perl
use warnings;
use strict;
use Jifty::Test::Dist tests => 4;
use Jifty::Test::Email;
use TestApp::Notifications::Notification;
use utf8;

sub send_mail {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $body = shift;

    Jifty::Test->setup_mailbox;

    my $notification = TestApp::Notifications::Notification->new;
    $notification->body($body);
    $notification->send_one_message;

    ok( $notification->body , 'body');

    # my @emails = Jifty::Test->messages;
    # Jifty::Test->teardown_mailbox;

    # is(scalar @emails, 1, "Sent one notification email");
    # return $emails[0]->body;
}

send_mail("中文");

sub read_mailbox {
    my $file = shift;
    local $/;
    my $mailbox = $file || Jifty::Test->mailbox;
    ok( -e $mailbox , 'mailbox file ok - ' . $mailbox );
    open my $fh, "<",$mailbox;
    binmode $fh, ":utf8";
    my $text = <$fh>;
    ok( $text , 'mail content ok' );
    close $fh;
    Jifty::Test->setup_mailbox;
    return $text;
}

my $mail = read_mailbox;
like($mail , qr'中文's );
