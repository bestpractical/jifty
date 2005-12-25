use warnings;
use strict;

package Jifty::CurrentUser;

use base qw/Jifty::Object/;

=head1 NAME

Jifty::CurrentUser

=head1 DESCRIPTION

Most applications need to have a concept of who the current user
is. So Jifty supports this concept internally. Every object (except
the currentuser) is instantiated with a Jifty::CurrentUser (or
subclass) as a parameter to the creator.

It's generally expected that your application will override this if
you want any sort of access control.

=cut

=head2 new

Creates a new L<Jifty::CurrentUser> object.

=cut

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

=head2 id

Returns zero.

=cut

sub id { 0 }

1;
