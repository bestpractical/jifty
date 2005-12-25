#!/usr/bin/perl
package Jifty::Mason;

use strict;
use warnings;
use File::Basename;


BEGIN {
  my $dir = dirname(__FILE__);
  push @INC, "$dir/../lib";
  push @INC, "$dir/../../Jifty/lib";
}

use Jifty::Script::FastCGI;
Jifty::Script::FastCGI->run();


1;
