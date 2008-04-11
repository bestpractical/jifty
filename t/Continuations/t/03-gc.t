#!/usr/bin/env perl

use warnings;
use strict;

# {{{ Setup
use lib 't/lib';
use Jifty::SubTest;

use Jifty::Test;

plan skip_all => "test file not done yet";

#### garbage collection
#  for now, an "on request, sweep all continuations older than the last 50"?
# continuations need a timestamp. so we can tell what's out of date.
