#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 3;

use Jifty::Everything;

# test that various parts of jifty work with UTF-8 in the right way

diag "escape_uri" if $ENV{TEST_VERBOSE};
{
    my $s = 'a';
    Jifty::View::Mason::Handler::escape_uri(\$s);
    is $s, 'a', 'ASCII';
    $s = "\x{E9}";
    Jifty::View::Mason::Handler::escape_uri(\$s);
    is $s, '%C3%A9', 'latin small letter e with accute';
    $s = "\x{435}";
    Jifty::View::Mason::Handler::escape_uri(\$s);
    is $s, '%D0%B5', 'russian small letter e';
}

