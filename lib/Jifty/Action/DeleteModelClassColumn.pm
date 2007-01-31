use strict;
use warnings;

package Jifty::Action::DeleteModelClassColumn;
use base qw/ Jifty::Action::Record::Delete /;

sub record_class { 'Jifty::Model::ModelClassColumn' }

1;
