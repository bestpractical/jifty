#!/usr/bin/env perl
use warnings;
use strict;

use Jifty::Test::Dist tests => 8;
use TestApp::Notifications::Notification;
use charnames ':full';
use utf8;

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
    return Email::MIME->new($emails[0]->as_string)->body_str . "\n";
}

{
    my $str = "Simple Latin-1\n\n";  # latin bytes string
    my $body = send_and_receive( $str );
    is($body, $str, "Latin looks fine" );
}

{
    my $str = "All L\N{LATIN SMALL LETTER E WITH ACUTE}on's fault\n\n";
    my $body = send_and_receive( $str );
    is($body, $str, "Implicit UTF8 char" );
}

{
    my $str = "中文\n\n\n";
    my $body = send_and_receive( $str );
    is($body, $str, "Explicit UTF8 char" );
}

{
    my $lh = Jifty::I18N->get_handle("ja");
    Jifty::I18N->install_global_loc(\$lh);

    my $str = _("Alert") . "\n\n";
    my $body = send_and_receive( $str );
    is($body, $str, "L10N UTF8 char" );
}
