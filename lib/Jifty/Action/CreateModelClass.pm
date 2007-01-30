use strict;
use warnings;

package Jifty::Action::CreateModelClass;
use base qw/ Jifty::Action::Record::Create /;

sub record_class { 'Jifty::Model::ModelClass' }

1;
