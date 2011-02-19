#!/usr/bin/env perl
use warnings;
use strict;

use Jifty::Test::Dist tests => 4;

use_ok('Jifty::Notification');
use_ok('Email::MIME::CreateHTML');
use_ok('Email::MIME');
use_ok('Email::Send');

my $html = "<html><body>This is the HTML portion of the test email</body></html>";

my $text = "This is the text portion of the text email";

my $test_email = Email::MIME->create_html(
    header => [
        From => 'test@test',
        To => 'test2@test2',
        Subject => 'This is a test email',
    ],
    body => $html,
    text_body => $text
);



# TODO: {local $TODO = "Actually write tests"; ok(0, "Test notifications")};

1;
