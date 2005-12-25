#!/usr/bin/perl
use warnings;
use strict;

package Jifty::Script::StandaloneServer;

use Jifty::Everything;
use Jifty::Server;

sub run {
    Jifty->new();
    Jifty::Server->new()->run;
}
1;
