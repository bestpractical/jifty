use warnings;
use strict;

package Jifty::Model::ModelClassColumnCollection;
use base qw/Jifty::Collection/;

=head2 record_class

This deals with collections of L<Jifty::Model::ModelClassColumn>s.

=cut 

sub record_class { 'Jifty::Model::ModelClassColumn' }


1;
