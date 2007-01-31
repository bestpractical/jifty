use strict;
use warnings;

package Jifty::Action::CreateModelClassColumn;
use base qw/ Jifty::Action::Record::Create /;

sub record_class { 'Jifty::Model::ModelClassColumn' }

1;
