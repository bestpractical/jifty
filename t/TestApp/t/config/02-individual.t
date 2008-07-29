#!/usr/bin/env perl
use strict;
use warnings;

use Jifty::Test::Dist;

my %option_from_file = (
    EtcConfig         => 'etc/config.yml',
    EtcSiteConfig     => 'etc/site_config.yml',
    TTestConfig       => 't/test_config.yml',
    TConfigTestConfig => 't/config/test_config.yml',
    IndividualFile    => 't/config/02-individual.t-config.tml ',
);

plan tests => 2 + keys %option_from_file;

ok(Jifty->config->framework('Web')->{'Port'} >= 10000, "default test config still exists");
is(Jifty->config->app('ThisConfigFile'), 't/config/02-individual.t-config.yml', "the same value merges correctly");

while (my ($option, $file) = each %option_from_file) {
    is(Jifty->config->app($option), '1', "options from $file loaded");
}

