#!/usr/bin/env perl
use strict;
use warnings;

=for your_eyes_only

Note that we CANNOT easily test for loading etc/config.yml: the usual way to
get t/TestApp* config is to C<use Jifty::SubTest>, which C<chdir>s into
TestApp. unfortunately that screws up the canonicalization of C<$0> (since it
is still relative to jifty, not TestApp), which finally screws up the config
loading, which use C<$0>.

The solution will probably be to have C<Jifty::SubTest> set some global
variable that we use instead of C<Cwd::cwd> in C<Jifty::Test::load_configs>.
Yes it sucks, but it beats the weirdness/portability of setting C<$0> (which
uses magic to actually change the program name for C<ps>).

=cut

use Jifty::Test;

my %option_from_file = (
    TTestConfig       => 't/test_config.yml',
    TConfigTestConfig => 't/config/test_config.yml',
);

plan tests => 3 + keys %option_from_file;

ok(Jifty->config->framework('Web')->{'Port'} >= 10000, "default test config still exists");
is(Jifty->config->app('ThisConfigFile'), 't/config/test_config.yml', "the same value merges correctly");

while (my ($option, $file) = each %option_from_file) {
    is(Jifty->config->app($option), '1', "options from $file loaded");
}

is(Jifty->config->app('IndividualFile'), undef, "options from t/config/02-individual.t-config.tml NOT loaded");

1;

