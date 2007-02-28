use strict;
use warnings;

package Jifty::Plugin::Authentication::Password::Model::User;
use Jifty::DBI::Schema;
use base 'Jifty::DBI::Record::Plugin';
use Jifty::Plugin::Authentication::Password::Record schema {
    column password => type is 'text', render as 'Password', is unreadable;
};


# Your model-specific methods go here.

1;

