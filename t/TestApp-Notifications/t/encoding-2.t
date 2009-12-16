#!/usr/bin/env perl
use warnings;
use strict;
use Jifty::Test tests => 4;
use Jifty::Test::Email;
use Test::Exception;

mail_ok  {
    my $n = Jifty->app_class( 'Notification' => 'Foo' )->new;
    $n->body( "Simple Latin-1\n\n" );
    $n->send_one_message;
    } { body => qr'Simple Latin-1's };

mail_ok  {
    my $n = Jifty->app_class( 'Notification' => 'Foo' )->new;
    $n->body( "中文\n\n\n" );
    $n->send_one_message;
    } { body => qr'中文's };

1;
