use warnings;
use strict;

package Jifty::Model::SessionCollection;

use base qw/Jifty::Collection/;

=head1 NAME

Jifty::Model::SessionCollection - Specialized handling of the session collection

=head2 METHODS

=head2 record_class

This deals with collections of L<Jifty::Model::Session>s.

=cut 

sub record_class { 'Jifty::Model::Session' }


=head2 current_user

Everyone is treated as the superuser when dealing with session
objects.  This avoids infinite recursion, as otherwise it would try to
look up the current user in the session object to find out who we
are...

=cut

sub current_user { return Jifty::CurrentUser->superuser }

1;
