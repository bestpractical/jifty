#!/usr/bin/env perl

use warnings;
use strict;

=head1 DESCRIPTION

This test performs some magic to start Jifty up a second time after Jifty::Test performs initialization. This is so we can cover additional hunks of code that have to do with the bootstrapping process on an existing Jifty database (i.e., building database-backed tables that were stored in a previous instance of the Jifty application that has now closed).

This is moderately ugly. Jifty::Test might might be modif

=cut

use lib 't/lib';
use Jifty::SubTest;

use Jifty::Test;

if (my $pid = fork) {
    waitpid($pid, 0);
}

else {
    chdir '../..';
    exec 'perl t/TestApp-DatabaseBackedModels/t/second-run.pl';
}
