use warnings;
use strict;

package Jifty::DateTime;

=head1 NAME

Jifty::DateTime - a DateTime subclass that knows about Jifty users

=head1 SYNOPSIS

  use Jifty::DateTime;
  
  # Get the current date and time
  my $dt = Jifty::DateTime->now;
  
  # Print out the pretty date (i.e., today, tomorrow, yesterday, or 2007-09-11)
  Jifty->web->out( $dt->friendly_date );

  # Better date parsing
  my $dt_from_human = Jifty::DateTime->new_from_string("next Saturday");

=head1 DESCRIPTION

Jifty natively stores timestamps in the database in GMT.  Dates are stored
without timezone. This class loads and parses dates and sets them
into the proper timezone.

To use this DateTime class to it's fullest ability, you'll need to add a C<time_zone> method to your application's user object class. This is the class returned by L<Jifty::CurrentUser/user_object>. It must return a value valid for using as an argument to L<DateTime>'s C<set_time_zone()> method.

=cut

BEGIN {
    # we spent about 30% of the time in validate during 'require
    # DateTime::Locale' which isn't necessary at all
    require Params::Validate;
    no warnings 'redefine';
    local *Params::Validate::validate = sub { pop @_, return @_ };
    require DateTime::Locale;
}

use base qw(Jifty::Object DateTime);

=head2 new ARGS

See L<DateTime/new>. If we get what appears to be a date, then we
keep this in the floating datetime. Otherwise, set this object's
timezone to the current user's time zone, if the current user has a
method called C<time_zone>.  

=cut

sub new {
    my $class = shift;
    my %args  = (@_);
    my $self  = $class->SUPER::new(%args);

    # XXX What if they really mean midnight offset by time zone?

    #     this behavior is (sadly!) consistent with
    #     DateTime->truncate(to => 'day') and Jifty::DateTime::new_from_string
    #     suggestions for improvement are very welcome

    # Do not bother with time zones unless time is used, we assume that
    # 00:00:00 implies that no time is used
    if ($self->hour || $self->minute || $self->second) {

        # Unless the user has explicitly said they want a floating time,
        # we want to convert to the end-user's timezone. If we ignore
        # $args{time_zone}, then DateTime::from_epoch will get very confused
        if (!$args{time_zone} and my $tz = $self->current_user_has_timezone) {
            $self->set_time_zone("UTC"); # XXX: why are we doing this?
            $self->set_time_zone( $tz );
        }
    }

    # No time, just use the floating time zone
    else {
        $self->set_time_zone("floating");
    }

    return $self;
}

=head2 now ARGS

See L<DateTime/now>. If a time_zone argument is passed in, then this method
is effectively a no-op.

OTHERWISE this will always set this object's timezone to the current user's
timezone (or UTC if that's not available). Without this, DateTime's C<now> will
set the timezone to UTC always (by passing C<< time_zone => 'UTC' >> to
C<Jifty::DateTime::new>. We want Jifty::DateTime to always reflect the current
user's timezone (unless otherwise requested, of course).

=cut

sub now {
    my $class = shift;
    my %args  = @_;
    my $self  = $class->SUPER::now(%args);

    $self->set_time_zone($self->current_user_has_timezone || 'UTC')
        unless $args{time_zone};

    return $self;
}

=head2 current_user_has_timezone

Return timezone if the current user has one. This is determined by checking to see if the current user has a user object. If it has a user object, then it checks to see if that user object has a C<time_zone> method and uses that to determine the value.

=cut

sub current_user_has_timezone {
    my $self = shift;
    $self->_get_current_user();

    # Can't continue if we have no notion of a user_object
    return unless $self->current_user->can('user_object');

    # Can't continue unless the user object is defined
    my $user_obj = $self->current_user->user_object or return;

    # Check for a time_zone method and then use it if it exists
    my $f = $user_obj->can('time_zone') or return;
    return $f->($user_obj);
}

=head2 new_from_string STRING

Take some user defined string like "tomorrow" and turn it into a
C<Jifty::Datetime> object.  If the string appears to be a _date_, keep
it in the floating timezone, otherwise, set it to the current user's
timezone.

As of this writing, this uses L<Date::Manip> along with some internal hacks to alter the way L<Date::Manip> normally interprets week day names. This may change in the future.

=cut

sub new_from_string {
    my $class  = shift;
    my $string = shift;
    my $now;

    # Hack to use Date::Manip to flexibly scan dates from strings
    {
        # Date::Manip interprets days of the week (eg, ''monday'') as
        # days within the *current* week. Detect these and prepend
        # ``next''
        # XXX TODO: Find a real solution (better date-parsing library?)
        if($string =~ /^\s* (?:monday|tuesday|wednesday|thursday|friday|saturday|sunday)$/xi) {
            $string = "next $string";
        }
        
        # Why are we parsing this as GMT? This feels really wrong.  It will get the wrong answer
        # if the current user is in another tz.
        require Date::Manip;
        Date::Manip::Date_Init("TZ=GMT");
        $now = Date::Manip::UnixDate( $string, "%o" );
    }

    # Stop here if Date::Manip couldn't figure it out
    return undef unless $now;

    # Build a DateTime object from the Date::Manip value and setup the TZ
    my $self = $class->from_epoch( epoch => $now, time_zone => 'gmt' );
    if (my $tz = $self->current_user_has_timezone) {
        $self->set_time_zone("floating")
            unless ( $self->hour or $self->minute or $self->second );
        $self->set_time_zone( $tz );
    }

    return $self;
}

=head2 friendly_date

Returns the date given by this C<Jifty::DateTime> object. It will display "today"
for today, "tomorrow" for tomorrow, or "yesterday" for yesterday. Any other date
will be displayed in ymd format.

=cut

sub friendly_date {
    my $self = shift;
    my $ymd = $self->ymd;

    # Use the current user's time zone on the date
    my $tz = $self->current_user_has_timezone || $self->time_zone;
    my $rel = DateTime->now( time_zone => $tz );

    # Is it today?
    if ($ymd eq $rel->ymd) {
        return "today";
    }

    # Is it yesterday?
    my $yesterday = $rel->clone->subtract(days => 1);
    if ($ymd eq $yesterday->ymd) {
        return "yesterday";
    }

    # Is it tomorrow?
    my $tomorrow = $rel->clone->add(days => 1);
    if ($ymd eq $tomorrow->ymd) {
        return "tomorrow";
    }
    
    # None of the above, just spit out the date
    return $ymd;
}

=head1 WHY?

There are other ways to do some of these things and some of the decisions here may seem arbitrary, particularly if you read the code. They are.

These things are valuable to applications built by Best Practical Solutions, so it's here. If you disagree with the policy or need to do it differently, then you probably need to implement something yourself using a DateTime::Format::* class or your own code. 

Parts may be cleaned up and the API cleared up a bit more in the future.

=head1 SEE ALSO

L<DateTime>, L<DateTime::TimeZone>, L<Jifty::CurrentUser>

=head1 LICENSE

Jifty is Copyright 2005-2007 Best Practical Solutions, LLC.
Jifty is distributed under the same terms as Perl itself.

=cut

1;
