use warnings;
use strict;

package Jifty::Model::MetadataCollection;

use base qw/Jifty::Collection/;

=head2 record_class

This deals with collections of L<Jifty::Model::Metadata>s.

=cut 

sub record_class { 'Jifty::Model::Metadata' }

1;
