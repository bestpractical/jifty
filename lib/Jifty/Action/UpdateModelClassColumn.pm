use strict;
use warnings;

package Jifty::Action::UpdateModelClassColumn;
use base qw/ Jifty::Action::Record::Update /;

sub record_class { 'Jifty::Model::ModelClassColumn' }

1;
