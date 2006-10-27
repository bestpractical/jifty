package Ping::Event::Pong;
use strict;
use warnings;
use base 'Ping::Event';

sub match {
    my $self    = shift;
    my $query   = shift;

    if ($query->{fail}) {
        not $$self->{alive};
    }
    elsif (my $host = $query->{host}) {
        $$self->{host} eq $host;
    }
    else {
        1;
    }
}

sub render_arguments {
    %{$_[0]->data};
}

1;
