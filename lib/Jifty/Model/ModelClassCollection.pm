use warnings;
use strict;

package Jifty::Model::ModelClassCollection;
use base qw/Jifty::Collection/;

=head2 record_class

This deals with collections of L<Jifty::Model::ModelClass>s.

=cut 

sub record_class { 'Jifty::Model::ModelClass' }


=head2 instantiate

Instantiate all model classes in this collection. See L<Jifty::Model::ModelClass/instantiate>.

=cut

sub instantiate {
    my $self = shift;
    for (@{$self->items_array_ref}) {
        $_->instantiate;
    }
}

1;
