#!/usr/bin/env perl -w
use strict;
use Test::More tests => 1;
use lib qw(lib);

use_ok('Jifty::Plugin::AuthzLDAP');
