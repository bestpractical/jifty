use warnings;
use strict;

package JFDI::Response;

use base qw/JFDI::Object Class::Accessor/;

=head1 NAME

JFDI::Response - Canonical internal representation of the result of a L<JFDI::Action>

=head1 DESCRIPTION

=cut

=head2 new

Creates a new L<JFDI::Response> object.

=cut

sub new {
    my $class = shift;
    bless {results => {}}, $class;
}

=head2 result MONIKER [RESULT]

Gets or sets the L<JFDI::Result> of the L<JFDI::Action> with the given
C<MONIKER>.

=cut

sub result {
    my $self = shift;
    my $moniker = shift;
    $self->{results}{$moniker} = shift if @_;
    return $self->{results}{$moniker};
}

=head2 results

Returns a hash which maps moniker to its L<JFDI::Result>

=cut

sub results {
    my $self = shift;
    return %{$self->{results}};
}

=head2 messages

=cut

sub messages {
    my $self = shift;
    my %results = $self->results;
    return map {$_, $results{$_}->message} grep {defined $results{$_}->message and length $results{$_}->message} keys %results;
}

=head2 success

Returns true if none of the results are failures

=cut

sub success {
    my $self = shift;
    return 1 unless grep {$_->failure} values %{$self->{results}};
    return 0;
}

=head2 failure

Returns true if any of the results failed

=cut

sub failure {
    my $self = shift;
    return not $self->success;
}

1;
