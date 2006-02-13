use warnings;
use strict;

package Jifty::Response;

use base qw/Jifty::Object Class::Accessor/;

=head1 NAME

Jifty::Response - Canonical internal representation of the result of a L<Jifty::Action>

=head1 DESCRIPTION

The answer to a L<Jifty::Request> is a C<Jifty::Response> object.
Currently, the response object exists merely to collect the
L<Jifty::Result> objects of each L<Jifty::Action> that ran.

=cut

=head2 new

Creates a new L<Jifty::Response> object.

=cut

sub new {
    my $class = shift;
    bless {results => {}, headers => []}, $class;
}

sub add_header {
    my $self = shift;
    # This one is so we can get jifty's headers into mason
    # Otherwise we'd have to wrap mason's output layer
     Jifty->handler->apache->header_out( @_ );


    push @{$self->{headers}}, [@_];
}

sub headers {
    my $self = shift;
    return @{$self->{headers}};
}

=head2 result MONIKER [RESULT]

Gets or sets the L<Jifty::Result> of the L<Jifty::Action> with the given
I<MONIKER>.

=cut

sub result {
    my $self = shift;
    my $moniker = shift;
    $self->{results}{$moniker} = shift if @_;
    return $self->{results}{$moniker};
}

=head2 results

Returns a hash which maps moniker to its L<Jifty::Result>

=cut

sub results {
    my $self = shift;
    return %{$self->{results}};
}

=head2 messages

Returns the aggregate messages of all of the L<Jifty::Result>s.

=cut

sub messages {
    my $self = shift;
    my %results = $self->results;
    return map {$_, $results{$_}->message} grep {defined $results{$_}->message and length $results{$_}->message} keys %results;
}

=head2 success

Returns true if none of the results are failures.

=cut

sub success {
    my $self = shift;
    return 1 unless grep {$_->failure} values %{$self->{results}};
    return 0;
}

=head2 failure

Returns true if any of the results failed.

=cut

sub failure {
    my $self = shift;
    return not $self->success;
}

1;
