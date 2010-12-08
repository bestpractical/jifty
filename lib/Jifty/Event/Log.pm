package Jifty::Event::Log;
use strict;
use warnings;
use base qw/Jifty::Event/;

=head1 NAME

Jifty::Event::Log - An event that L<Jifty::Logger::EventAppender> creates

=head1 DESCRIPTION

This L<Jifty::Event> is created when a log message happens.

=head1 METHODS

=head2 match QUERY

Matches only if all of the keys in the query exist in the data, and
the values of the keys match the respective values in the data.

=cut

sub match {
    my $self    = shift;
    my $query   = shift;

    for my $key (keys %{$query}) {
        return unless defined $self->data->{$key} and $self->data->{$key} eq $query->{$key};
    }

    return 1;
}

=head2 render_arguments

All of the data is dumped into the rendered arguments, verbatim.

=cut

sub render_arguments {
    my $self = shift;
    return ( %{ $self->data } );
}

1;
