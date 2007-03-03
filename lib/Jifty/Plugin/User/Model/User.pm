use strict;
use warnings;

package Jifty::Plugin::User::Model::User;
use Jifty::DBI::Schema;


=head1 NAME

Jifty::Plugin::User::Model::User

=DESCRIPTION

package MyApp::Model::User;

use Jifty::DBI::Schema;

use MyApp::Record schema { 

    # column definitions

};

use Jifty::Plugin::User::Model::User; # Imports two columns: name and username


=cut


use base 'Jifty::DBI::Record::Plugin';
use Jifty::Plugin::User::Record schema {
    column name => type is 'text', label is 'How should I display your name?';
    column username => type is 'text';
};


# Your model-specific methods go here.

1;

