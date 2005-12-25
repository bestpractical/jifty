use warnings;
use strict;

package Jifty::CurrentUser;

use base qw/Jifty::Object Class::Accessor/;

__PACKAGE__->mk_accessors(qw(is_superuser is_bootstrap_user user_object));


=head1 NAME

Jifty::CurrentUser

=head1 DESCRIPTION

Most applications need to have a concept of who the current user
is. So Jifty supports this concept internally. Every object (except
the currentuser) is instantiated with a Jifty::CurrentUser (or
subclass) as a parameter to the creator.


This class describes (and implements a trivial version) of the access control API that a Jifty application needs to implemenet to provide user-based
access control

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
    $self->_init(@_);
    return $self;
}

sub _init { 1}


=head2 id

Returns C<0> if we don't have a user_object. 
When we I<do> have a user_object, return that user's id.
When your application subclasses this class,  L</id> should return the integer id for the current user.

=cut

sub id {
    my $self = shift;
    if ($self->user_object) {
        return ($self->user_object->id());
    } else {
        return '0';
    }

}

=head2 current_user

Every class in a Jifty application has a L</current_user> method that returns the user 
who's doing things, in the form of a L<Jifty::CurrentUser> object a subclass thereof.
For the somewhat obvious reason that you can't actually lift yourself up by tugging on your own bootstraps, a Jifty::CurrentUser object return I<itself> rather than another C<Jifty::CurrentUser object>

=cut

sub current_user {
    my $self = shift;
    return $self;
}


=head2 user_object 

This gets or sets your application's user object for the current user. Generally, you're epxected to set and load it in the _init method in your subclass

=cut


=head1 USERNAME AND PASSWORD ROUTINES

=head2 username

=head2 password_is STRING

Your L<user_object> should have a method called C<password_is> which returns true if passed a string
that matches the user's current password.

=cut

sub password_is {
    my $self = shift;
    return undef unless ($self->user_object);
    return($self->user_object->password_is(@_));

}



=head2 set_password


=head1 OTHER USER METADATA

=head2 email

=cut

sub email {'undefined'}


=head2 email_address_confirmed


=head1 TOKEN BASED AUTHENTICATION

=head2 insecure_auth_token


=cut

sub insecure_url_auth_token {
    my $self = shift;
    return ($self->user_object->insecure_url_auth_token);

}


=head1 ABILITY TO LEAP TALL BUILDINGS IN A SINGLE BOUND

In any system that relies on users' rights to perform actions, it's sometimes
necessary to walk around the access control system. There are two primary
cases for this:


=head2 is_superuser 

Sometimes, while the system is running, you need to do something on behalf of a user that they shouldn't be able to do themselves. Maybe you need to let a new user sign up for your service (You don't want to let any user create more users, right?) or to write an entry to a changelog. If the user has the C<is_superuser> flag set, things still get read from the database, but the user can walk around any and all ACL checks. Think "Neo" from the Matrix. The superuser can walk through walls, stop bullets and so on.


=cut

=head2 is_bootstrap_user

When your system is first getting going, you can't assume B<anything>. There
probably aren't any rights in the system to check. A user with the L</is_bootstrap_user> flag set is a self-reliant superuser. Nothing is read from the database, no ACLs are checked.  You probably never need to do anything with bootstrap users.

=cut

1;
