use warnings;
use strict;

package Jifty::Model::SessionCollection;

use base qw/Jifty::Collection/;
sub record_class { 'Jifty::Model::Session' }


=head2 current_user

Everyone is treated as the superuser when dealing with session
objects.  This avoids infinite recursion, as otherwise it would try to
look up the current user in the session object to find out who we
are...

=cut

sub current_user { return Jifty::CurrentUser->superuser }

1;
