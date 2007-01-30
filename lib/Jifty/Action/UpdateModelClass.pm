use strict;
use warnings;

package Jifty::Action::UpdateModelClass;
use base qw/ Jifty::Action::Record::Update /;

sub record_class { 'Jifty::Model::ModelClass' }

1;
