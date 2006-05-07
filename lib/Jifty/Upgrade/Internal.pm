use strict;
use warnings;

package Jifty::Upgrade::Internal;
use Jifty::Upgrade;
use base qw/Jifty::Upgrade/;
use Jifty::Model::Metadata;

# XXX TODO: there's probably a cleaner way to cope than "INITIAL_VERSION", perhaps using ->VERSIONS
our $INITIAL_VERSION;

=head2 Version 0.60427

Version metadata, previously stored in _db_version, get migrated to
_jifty_metadata, so it could be used to store more than one row
usefully.

=cut

since '0.60427' => sub {
    my @v = Jifty->handle->fetch_result("SELECT major, minor, rev FROM _db_version");
    Jifty->handle->simple_query("DROP TABLE _db_version");
    Jifty::Model::Metadata->store( application_db_version => version->new(join'.',@v));
    # Since we broke things before 0.60504 but fixed them shortly thereafter,
    # Make sure the user doesn't run the 060504 upgrade unless they must
    $INITIAL_VERSION = '0.60427';
};

since '0.60504' => sub { 
    return if ($INITIAL_VERSION == '0.60427');
    rename column => 'key', in => 'Jifty::Model::Session',  to => 'data_key';
    rename column => 'key', in => 'Jifty::Model::Metadata', to => 'data_key';
};

1;
