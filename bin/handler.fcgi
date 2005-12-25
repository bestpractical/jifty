#!/usr/bin/perl

use strict;
use warnings;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
BEGIN {
    my $dir = dirname(abs_path($0));
    push @INC, "$dir/../lib";
    push @INC, "$dir/../../Jifty/lib";
}   

use Jifty::Script::FastCGI;
Jifty::Script::FastCGI->run();


1;
