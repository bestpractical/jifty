use warnings;
use strict;

package Jifty::DateTime;

=head1 NAME

Jifty::DateTime - a DateTime subclass that knows about Jifty users 

=head1 DESCRIPTION

Jifty natively stores timestamps in the database in GMT.  Dates are stored
without timezone. This class loads and parses dates and sets them 
into the proper timezone.

=cut

use base qw'Jifty::Object DateTime';

use Date::Manip ();

=head2 new ARGS

See L<DateTime/new>.  After calling that method, set this object's
timezone to the current user's time zone, if the current user has a
method called C<time_zone>.

=cut

sub new {
    my $class = shift;
    my %args  = (@_);
    my $self  = $class->SUPER::new(%args);

    # Unless the user has explicitly said they want a floating time,
    # we want to convert to the end-user's timezone.  This is
    # complicated by the fact that DateTime auto-appends
    $self->_get_current_user();
    my $user_obj = $self->current_user->user_object;
    if (    $user_obj
        and $user_obj->can('time_zone')
        and $user_obj->time_zone )
    {
        $self->set_time_zone("UTC");
        $self->set_time_zone( $user_obj->time_zone );

    }
    return $self;
}

=head2 new_from_string STRING

Take some user defined string like "tomorrow" and turn it into a
C<Jifty::Datetime> object.  If the string appears to be a _date_, keep
it in the floating timezone, otherwise, set it to the current user's
timezone.

=cut

sub new_from_string {
    my $class  = shift;
    my $string = shift;
    my $now;
    {
        # Date::Manip interprets days of the week (eg, ''monday'') as
        # days within the *curent* week. Detect these and prepend
        # ``next''
        # XXX TODO: Find a real solution (better date-parsing library?)
        if($string =~ /^\s* (?:monday|tuesday|wednesday|thursday|friday|saturday|sunday)$/xi) {
            $string = "next $string";
        }
        local $ENV{'TZ'} = "GMT";
        $now = Date::Manip::UnixDate( $string, "%o" );
    }
    return undef unless $now;
    my $self = $class->from_epoch( epoch => $now, time_zone => 'gmt' );
    $self->_get_current_user();
    if (    $self->current_user->user_object
        and $self->current_user->user_object->can('time_zone')
        and $self->current_user->user_object->time_zone )
    {

        # If the DateTime we've been handed appears to actually be at
        # a "time" then we want to make sure we get it to be that time
        # in the local timezone
        #
        # If we had only a date, then we want to switch it to the
        # user's timezone without adjusting the "time", as that could
        # make 2006-12-01 into 2006-11-30
        $self->set_time_zone("floating")
            unless ( $self->hour or $self->minute or $self->second );
        $self->set_time_zone( $self->current_user->user_object->time_zone );
    }
    return $self;
}

1;
