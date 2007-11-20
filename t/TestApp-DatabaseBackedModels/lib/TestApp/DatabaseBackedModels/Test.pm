use strict;
use warnings;

package TestApp::DatabaseBackedModels::Test;

use lib '../../lib';

use Jifty::Test ();
use base qw/ Jifty::Test /;

use File::Path;

=head1 DESCRIPTION

Used as part of the F<second-run.t> test to make sure that the database is not bootstrapped again so that we can use a database that's already been bootstrapped in a previous run of Jifty.

=cut

sub setup {
    my $class = shift;

    my $test_config = File::Temp->new( UNLINK => 0 );
    Jifty::YAML::DumpFile("$test_config", $class->test_config(Jifty::Config->new));
    # Invoking bin/jifty and friends will now have the test config ready.
    $ENV{'JIFTY_TEST_CONFIG'} ||= "$test_config";
    $class->builder->{test_config} = $test_config;
    {
        # Cache::Memcached stores things. And doesn't let them expire
        # from the cache easily. This is fine in production, but
        # during testing each test script needs its own namespace.  we
        # use the pid of the current process, and save it so the keys
        # stays the same when we fork
      {
          package Jifty::Record;
          no warnings qw/redefine/;

          use vars qw/$cache_key_prefix/;

          $cache_key_prefix = "jifty-test-" . $$;
        
          sub cache_key_prefix {
              $Jifty::Record::cache_key_prefix;
          }
      }
        
    }
    my $root = Jifty::Util->app_root;

    # Mason's disk caching sometimes causes false tests
    rmtree([ File::Spec->canonpath("$root/var/mason") ], 0, 1);

    Jifty->new;

    $class->setup_mailbox;
}

sub _testfile_to_dbname {
    my $dbname = 'ppdatabasebackedmodelstsecondrun';
    if (-f "testapp_databasebackedmodels".$dbname) {
        return $dbname;
    }
    else {
        Test::More::diag(`ls `);
        die "Database does not exist: $dbname";
    }
}

1;
