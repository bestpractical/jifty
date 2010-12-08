use strict;
use warnings;

package Jifty::Upgrade::Internal;
use Jifty::Upgrade;
use base qw/Jifty::Upgrade/;
use Jifty::Model::Metadata;

# XXX TODO: there's probably a cleaner way to cope than "INITIAL_VERSION", perhaps using ->VERSIONS
our $INITIAL_VERSION;

=head1 NAME

Jifty::Upgrade::Internal - Upgrades to Jifty-specific schema and data

=head1 UPGRADES

=head2 Version 0.60427

Version metadata, previously stored in _db_version, get migrated to
_jifty_metadata, so it could be used to store more than one row
usefully.

=cut

since '0.61025' => sub {
    Jifty::Util->require('IPC::PubSub');
    IPC::PubSub->new(
        JiftyDBI => (
            db_config    => Jifty->handle->{db_config},
            table_prefix => '_jifty_pubsub_',
            db_init      => 1,
        )
    );
};

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

since '0.61210' => sub { 
    Jifty::Util->require('IPC::PubSub');
    IPC::PubSub->new(
        JiftyDBI => (
            db_config    => Jifty->handle->{db_config},
            table_prefix => '_jifty_pubsub_',
            db_init      => 0,
        )
    );

    rename column => 'key', in => 'IPC::PubSub::Cache::JiftyDBI::Stash::Item', to => 'data_key';
};

1;
