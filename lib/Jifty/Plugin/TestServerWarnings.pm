use strict;
use warnings;

package Jifty::Plugin::TestServerWarnings;
use base qw/Jifty::Plugin/;

use LWP::Simple qw//;
use Jifty::Plugin::TestServerWarnings::Appender;

=head2 NAME

Jifty::Plugin::TestServerWarnings - Stores server warnings away for later fetching

=head2 DESCRIPTION

This plugin removes the default "Screen" appender on the first request
it sees, replacing it with a
L<Jifty::Plugin::TestServerWarnings::Appender>, which stores away all
messages it receives.  The warnings can be retrieved by a client-side
process by calling L</decoded_warnings> with a base URI to the server.

This plugin is automatically added for all jifty tests.

=head2 METHODS

=head3 new_request

On the first call to new_request, the plugin adjusts the appenders.
This causes it to only have effect if it is run in a forked server
process, not in a test process.  If C<TEST_VERBOSE> is set, it does
not remove the Screen appender.

=cut

sub new_request {
    my $self = shift;
    return if $self->{init}++;

    my $root = Log::Log4perl->get_logger("");
    $root->remove_appender("Screen") unless $ENV{TEST_VERBOSE};
    my $a = Jifty::Plugin::TestServerWarnings::Appender->new(name => "TestServerAppender");
    $root->add_appender($a);
}

=head3 add_warnings WARN, WARN, ..

Takes the given warnings, and stores them away for later reporting.

=cut

sub add_warnings {
    my $self = shift;
    push @{ $self->{'stashed_warnings'} }, @_;
}

=head3 stashed_warnings

Returns the stored warnings, as a list.  This does not clear the list,
unlike L</encoded_warnings> or L</decoded_warnings>.

=cut


sub stashed_warnings {
    my $self = shift;
    return @{ $self->{'stashed_warnings'} || [] };
}

=head3 encoded_warnings

Returns the stored warnings, encoded using L<Storable>.  This also
clears the list of stashed warnings.

=cut

sub encoded_warnings {
    my $self = shift;
    my @warnings = splice @{ $self->{'stashed_warnings'} };

    return Storable::nfreeze(\@warnings);
}

=head3 decoded_warnings URI

Given the URI to a jifty server with this plugin enabled, retrieves
and decodes the stored warnings, returning them.  This will also clear
the server's stored list of warnings.

=cut

sub decoded_warnings {
    my $self = shift;
    my $base = shift;

    my $uri = URI->new_abs( "/__jifty/test_warnings", $base );
    my $text = LWP::Simple::get($uri);

    return @{ Storable::thaw($text) };
}

1;
