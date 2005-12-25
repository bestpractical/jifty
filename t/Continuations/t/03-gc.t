#!/usr/bin/perl

use warnings;
use strict;

# {{{ Setup
BEGIN { -d 't/Continuations' &&  chdir 't/Continuations'; require 't/utils.pl'; };
use Test::More 'skip_all' => "test file not done yet";

#### garbage collection
#  for now, an "on request, sweep all continuations older than the last 50"?
# continuations need a timestamp. so we can tell what's out of date.
