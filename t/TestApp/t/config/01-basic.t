#!/usr/bin/env perl
use strict;
use warnings;

use lib 't/lib';
use Jifty::SubTest;

use Jifty::Test;

my %option_from_file = (
    EtcConfig         => 'etc/config.yml',
    EtcSiteConfig     => 'etc/site_config.yml',
    TTestConfig       => 't/test_config.yml',
    TConfigTestConfig => 't/config/test_config.yml',
);

my %no_option_from_file = (
    IndividualFile    => 't/config/02-individual.t-config.yml',
);

plan tests => 2 + keys(%option_from_file) + keys %no_option_from_file;

ok(Jifty->config->framework('Web')->{'Port'} >= 10000, "default test config still exists");
is(Jifty->config->app('ThisConfigFile'), 't/config/test_config.yml', "the same value merges correctly");

while (my ($option, $file) = each %option_from_file) {
    is(Jifty->config->app($option), '1', "options from $file loaded");
}

while (my ($option, $file) = each %no_option_from_file) {
    is(Jifty->config->app($option), undef, "options from $file NOT loaded");
}

