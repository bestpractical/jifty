use strict;
use warnings;

package Jifty::Action::DeleteModelClass;
use base qw/ Jifty::Action::Record::Delete /;

sub record_class { 'Jifty::Model::ModelClass' }

1;
