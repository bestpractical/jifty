#!/usr/bin/perl -w
use strict;
use Test::More tests => 2;

# TODO: check everything like this?
use ExtUtils::MakeMaker;
use_ok('Jifty::JSON');
ok(MM->parse_version($INC{'Jifty/JSON.pm'}));

