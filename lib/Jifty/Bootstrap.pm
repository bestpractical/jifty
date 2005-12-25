use warnings;
use strict;

=head1 NAME

Jifty::Bootstrap

=head1 DESCRIPTION

C<Jifty::Bootstrap> is an abstract baseclass for your application's bootstrapping.
Use it to set up configuration files, initialize databases, etc.

=cut

package Jifty::Bootstrap;

use base qw/Jifty::Object/;

=head2 run

C<run> is the workhorse method for the Bootstrap class. This takes care of setting up 
internal datastrutures and initializing things, in an application-dependent manner.

=cut

sub run { 
    1;
}


1;
