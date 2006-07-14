#!/usr/bin/perl
use warnings;
use strict;

use lib 't/lib';
use Jifty::SubTest;

use Jifty::Test tests => 2;
use_ok('Jifty::Notification');

TODO: {local $TODO = "Actually write tests"; ok(0, "Test notifications")};

1;
