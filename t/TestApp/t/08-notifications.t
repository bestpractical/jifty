#!/usr/bin/env perl
use warnings;
use strict;

use lib 't/lib';
use Jifty::SubTest;

use Jifty::Test tests => 3;
use_ok('Jifty::Notification');
use_ok('Email::MIME::CreateHTML');
use_ok('Email::MIME');

TODO: {local $TODO = "Actually write tests"; ok(0, "Test notifications")};

1;
