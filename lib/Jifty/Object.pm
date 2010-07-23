use warnings;
use strict;

package Jifty::Object;

use Log::Log4perl ();

=head1 NAME

Jifty::Object - Base class for most of Jifty's objects

=head1 DESCRIPTION

C<Jifty::Object> is the superclass of most of Jifty's objects.  It is
used to provide convenient accessors to important global objects like
the database handle or the logger object, while still allowing
individual classes to overload these methods.

We ought to be able to mix-in C<Jifty::Object> with any other class;
thus, we will not define C<new> or C<_init> in C<Jifty::Object>.  We
do assume, however, that C<$self> is a blessed hash reference.

=head1 METHODS

=head2 current_user [USER]

Gets/sets a user for the current user for this object.  You often do
not need to call this explicitly; Jifty will inspect your caller's
C<current_user>, and so on up the call stack.

=cut


sub current_user {
    my $self = shift;
    unless (ref($self)) {
        Carp::cluck("Called current_user as a class method!  This has no chance of working.  Fix your code.");
    }
    $self->{'_current_user'} = shift if (@_); 
    return($self->{'_current_user'});
}

=head2 PRIVATE _get_current_user

Takes the ARGS paramhash passed to _init.
Find the current user. First, try to see if it's explicit.
After that, check the caller's current_user. After that, look
at Jifty->web->current_user

Fills in current_user with that value

=cut


sub _get_current_user {
    my $self = shift;
    my %args = (@_);

    return if ( ref($self) && $self->current_user );

    if ( $args{'current_user'} ) {
        return $self->current_user( $args{'current_user'} );
    }

    my $cu;

    # Mason introduces a DIE handler that generates a mason exception
    # which in turn generates a backtrace. That's fine when you only
    # do it once per request. But it's really, really painful when you do it
    # often, as is the case with fragments
    #
    local $SIG{__DIE__} = 'DEFAULT';
    eval {
        package DB;

        my $depth = 2;
        while ( not $cu and $depth < 10 ) {
            # get the caller in array context to populate @DB::args
            my ($package) = CORE::caller( $depth++ );
            last if defined $package and $package eq "HTML::Mason::Commands";
            my $caller_self = $DB::args[0];
            next unless ref($caller_self);    #skip class methods;
            next unless my $s = $caller_self->can('current_user');
            next unless my $t = $s->($caller_self);
            next unless defined $t->id;
            $cu = $t;
        }
    };

    # Just return it if we're a cless method
    return $cu || Jifty->web->current_user unless ref $self;

    # If we found something, return it
    return $self->current_user( $cu ) if $cu;

    # Fallback to web ui framework
    return $self->current_user( Jifty->web->current_user ) if Jifty->web;

    return undef;
}


sub _handle {
    return Jifty->handle();
}

=head2 log

Returns a L<Log::Log4perl> logger object; the category of the logger
is the same as the class of C<$self>.

=cut

sub log {
    my $self = shift;

    return Log::Log4perl->get_logger(ref($self) || $self);
}


1;
