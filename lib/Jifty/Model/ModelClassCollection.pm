use warnings;
use strict;

package Jifty::Model::ModelClassCollection;
use base qw/Jifty::Collection/;

=head2 record_class

This deals with collections of L<Jifty::Model::ModelClass>s.

=cut 

sub record_class { 'Jifty::Model::ModelClass' }


1;
