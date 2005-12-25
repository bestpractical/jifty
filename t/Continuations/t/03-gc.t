#!/usr/bin/perl

use warnings;
use strict;

# {{{ Setup
BEGIN {chdir "t/Continuations"}
use lib '../../lib';
use Jifty::Test skip_all => "test file not done yet";

#### garbage collection
#  for now, an "on request, sweep all continuations older than the last 50"?
# continuations need a timestamp. so we can tell what's out of date.
