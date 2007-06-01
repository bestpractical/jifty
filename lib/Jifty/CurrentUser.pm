use warnings;
use strict;

package Jifty::CurrentUser;

use base qw/Jifty::Object Class::Accessor::Fast/;

__PACKAGE__->mk_accessors(qw(is_superuser is_bootstrap_user user_object));


=head1 NAME

Jifty::CurrentUser

=head1 DESCRIPTION

Most applications need to have a concept of who the current user
is. So Jifty supports this concept internally. Every L<Jifty::Object>
(which most things in Jifty are descended from) except the CurrentUser
itself is instantiated with a L<Jifty::CurrentUser> subclass as a
parameter to the creator.

This class describes (and implements a trivial version) of the access
control API that a Jifty application needs to implement to provide
user-based access control

It's generally expected that your application will override this class
if you want any sort of access control.

=cut

=head2 new

Creates a new L<Jifty::CurrentUser> object.  Calls L<_init>, an
app-specific initialization routine.

If you call it with the C<_bootstrap> argument, Jifty will set the user up as a bootstrap user, who's usually allowed to do just about anything without any access control

=cut

sub new {
    my $class = shift;
    my $self  = {};
    bless $self, (ref $class || $class);
    my %args = (@_);
    if ( delete $args{'_bootstrap'} ) { $self->is_bootstrap_user(1); }
    $self->_init(%args);
    return $self;
}


sub _init {
	    my $self = shift;
	    my %args = (@_);
	
            if (keys %args and UNIVERSAL::can(Jifty->app_class('Model', 'User'), 'new')  ) {
                
	        $self->user_object(Jifty->app_class('Model', 'User')->new(current_user => $self));
	        $self->user_object->load_by_cols(%args);
	    }
        return 1;
}
	

=head2 superuser

A convenience constructor that returns a new CurrentUser object that's
marked as a superuser. Can be called either as a class or object method.

=cut

sub superuser {
    my $class = shift;
    $class = ref( $class ) if ref $class;
    my $self = $class->new();
    $self->is_superuser(1);
    return $self;
}

=head2 user_object 

This gets or sets your application's user object for the current
user. Generally, you're expected to set and load it in the _init method
in your L<Jifty::CurrentUser> subclass.

If you do nothing, code similar to this will be called by _init.

	sub _init {
	    my $self = shift;
	    my %args = (@_);
	
            if (keys %args) {
	        $self->user_object(Wifty::Model::User->new(current_user => $self));
	        $self->user_object->load_by_cols(%args);
	    }
	}
	

=cut

=head2 id

Returns C<0> if we don't have a L<user_object>.  When we I<do> have a
user_object, return that user's id.

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

Every class in a Jifty application has a L</current_user> method that
returns the user who's doing things, in the form of a
L<Jifty::CurrentUser> object a subclass thereof.  For the somewhat
obvious reason that you can't actually lift yourself up by tugging on
your own bootstraps, a L<Jifty::CurrentUser> object return I<itself>
rather than another C<Jifty::CurrentUser object>

=cut

sub current_user {
    my $self = shift;
    return $self;
}

=head1 AUTHENTICATION AND AUTHORIZATION

To use Jifty's built-in authentication and authorization system, your
user objects need to implement the following API methods:

=head2 password_is STRING

Your L<user_object> should have a method called C<password_is> which
returns true if passed a string that matches the user's current
password.

=cut

sub password_is {
    my $self = shift;
    return undef unless ($self->user_object);
    return($self->user_object->password_is(@_));

}

=head2 username

Return a string which identifies the user in some way.

=cut

sub username {
    my $self = shift;
    return undef unless ($self->user_object);
    return($self->user_object->brief_description(@_));
}

=head2 auth_token

Return a string which proves that the user is who they claim to be.  A
simple way to do this, for example, would be to hash the username and
some server-side secret.

=cut

sub auth_token {
    my $self = shift;
    return undef unless ($self->user_object);
    return ($self->user_object->auth_token);

}

=head1 RIGHTS AND ACCESS CONTROL

In any system that relies on users' rights to perform actions, it's
sometimes necessary to walk around the access control system. There
are two primary cases for this:

=cut

=head2 is_superuser 

Sometimes, while the system is running, you need to do something on
behalf of a user that they shouldn't be able to do themselves. Maybe
you need to let a new user sign up for your service (You don't want to
let any user create more users, right?) or to write an entry to a
changelog. If the user has the C<is_superuser> flag set, things still
get read from the database, but the user can walk around any and all
ACL checks. Think "Neo" from the Matrix. The superuser can walk
through walls, stop bullets and so on.


=cut

=head2 is_bootstrap_user

When your system is first getting going, you can't assume
B<anything>. There probably aren't any rights in the system to
check. A user with the L</is_bootstrap_user> flag set is a
self-reliant superuser. Nothing is read from the database, no ACLs are
checked.  You probably never need to do anything with bootstrap users.

=cut


=head2 current_user_can ACTION

For a current user object, the current user can always C<read>, but
never write or do anything else.

=cut


sub current_user_can {
    my $self = shift;
    my $action = shift;
    return (1) if $action eq 'read';
    return (0);
}

1;
