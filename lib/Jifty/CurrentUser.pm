use warnings;
use strict;

package JFDI::CurrentUser;

use base qw/JFDI::Object/;

=head1 NAME

JFDI::CurrentUser

=head1 DESCRIPTION

Most applications need to have a concept of who the current user is. So JFDI supports this 
concept internally. Every object (except the currentuser) is instantiated with a JFDI::CurrentUser (or subclass)
as a parameter to the creator.

It's generally expected that your application will override thsi if you want any sort of access control.

=cut

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}
