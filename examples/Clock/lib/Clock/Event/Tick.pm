package Clock::Event::Tick;
use strict;
use warnings;
use base 'Clock::Event';

sub match {
    my $self    = shift;
    my $query   = shift;
    if (my $like = $query->{like}) {
        return(index($$self, $like) >= 0);
    }
    return 1;
}

1;
