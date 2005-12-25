use warnings;
use strict;

package Jifty::Object;

use Log::Log4perl;
use HTML::Entities;

=head1 Jifty::Object

C<Jifty::Object> is the superclass of most of Jifty's objects.  It is
used to provide convenient accessors to important global objects like
the database handle or the logger object, while still allowing individual
classes to overload these methods.

We ought to be able to mix-in C<Jifty::Object> with any other class; thus,
we will not define C<new> or C<_init> in C<Jifty::Object>, and we will not
make any assumptions about the underlying representation of C<$self>.

=cut

=head2 current_user [USER]

Gets/sets a user for the current user for this object.

=cut


sub current_user {
    my $self = shift;
    $self->{'_current_user'} = shift if (@_); 
    use Carp qw/croak/; croak unless (ref $self);
    return($self->{'_current_user'});

}

=for private _get_current_user ARGS

Takes the ARGS paramhash passed to _init. Looks
     Find the current user. First, try to see if it's explicit.
     After that, check the caller's current_user. After that, look
     at Jifty->framework->current_user

Fills in current_user with that value

=cut


sub _get_current_user {
    my $self = shift;
    my %args = (@_);

    return if ( $self->current_user );

    if ( $args{'current_user'} ) {
        return $self->current_user( $args{'current_user'} );
    }
    my $current_user;
    my $depth = 1;
    my $caller;
    eval {


        package DB;

        # get the caller in array context to populate @DB::args
        while (  not $current_user and $depth < 10) {
            #local @DB::args;
            my ($package, $filename, $line, $subroutine, $hasargs,
                               $wantarray, $evaltext, $is_require, $hints, $bitmask)= caller( $depth++ );
            my $caller_self      = $DB::args[0];
            next unless (ref($caller_self)); #skip class methods;
            next if ($caller_self eq $self);
            next unless UNIVERSAL::can($caller_self => 'current_user');

            eval {
            if ( $caller_self->current_user and $caller_self->current_user->id) {
                return($self->current_user($caller_self->current_user() ));
            } };
            # Skip all that error checking
        } 
    };


    if ( Jifty->framework ) {
        return $self->current_user( Jifty->framework->current_user );
    }

    return undef;
}


sub _handle {
    return Jifty->handle();
}

=head2 log

Returns a L<Log::Log4perl> logger object; the category of the logger
is the same as the subclass of C<$self>.

=cut

sub log {
    my $self = shift;

    return Log::Log4perl->get_logger(ref $self);
}


1;
